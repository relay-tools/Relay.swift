import Combine
import Foundation
import Relay

class RefetchFragmentLoader<Fragment: Relay.RefetchFragment>: ObservableObject {
    typealias RefetchVariables = Fragment.Operation.Variables

    let metadata: Fragment.Metadata
    let fragmentLoader: FragmentLoader<Fragment>

    @Published var snapshot: Snapshot<Fragment.Data?>?
    @Published var refetchKey = UUID()
    var isRefetchLoaded = false
    var refetchOperation: OperationDescriptor?

    private var fragmentLoaderCancellable: AnyCancellable?
    private var refetchCancellable: AnyCancellable?
    private var retainCancellable: AnyCancellable?
    private var doneRefetching: (() -> Void)?

    init() {
        self.metadata = Fragment.metadata
        self.fragmentLoader = FragmentLoader()

        fragmentLoader.$snapshot.assign(to: &$snapshot)
   }

    func load(from resource: FragmentResource, queryResource: QueryResource, key: Fragment.Key) {
        if let refetchOperation = refetchOperation {
            // this prevents a cycle where we re-establish this pipeline every time the data updates.
            // instead we only do it explicitly after a new refetch is initiated.
            if isRefetchLoaded {
                return
            }

            refetchCancellable = queryResource.prepare(
                operation: refetchOperation,
                cacheConfig: CacheConfig(force: true),
                cacheKeyBuster: refetchKey
            ).sink { [weak self] result in
                guard let self = self else { return }

                switch result {
                case nil:
                    self.snapshot = nil
                case .failure:
                    self.snapshot = nil
                    self.stopRefetchingIfNeeded()
                case .success(let queryResult):
                    self.retainCancellable = queryResource.retain(queryResult)

                    let identifier = queryResult.fragmentNode.identifier(for: queryResult.fragmentRef)
                    let fragmentResult: FragmentResource.FragmentResult<SelectorData> =
                        resource.read(node: queryResult.fragmentNode, ref: queryResult.fragmentRef, identifier: identifier)

                    guard let queryData = fragmentResult.data else {
                        preconditionFailure("Expected to have valid data from refetch query")
                    }

                    let fragmentNode = Fragment.node
                    let fragmentObject = queryData.get(path: self.metadata.fragmentPathInResult) as! SelectorData
                    let fragmentRef = fragmentObject.get(fragment: fragmentNode.name)!

                    self.fragmentLoader.load(from: resource, node: fragmentNode, ref: fragmentRef)
                    self.stopRefetchingIfNeeded()
                }
            }

            isRefetchLoaded = true
        } else {
            fragmentLoader.load(from: resource, key: key)
        }
    }

    var data: Fragment.Data? {
        fragmentLoader.data
    }

    var environment: Environment! {
        fragmentLoader.environment
    }

    var selector: SingularReaderSelector? {
        fragmentLoader.selector
    }

    func refetch(_ variables: RefetchVariables?, from resource: FragmentResource, queryResource: QueryResource, key: Fragment.Key) async {
        guard var variables = variables?.variableData ?? selector?.owner.variables else {
            preconditionFailure("Attempting to refetch before the fragment has even been loaded")
        }

        await withUnsafeContinuation { (continuation: UnsafeContinuation<Void, Never>) in
            doneRefetching = continuation.resume

            if let identifierField = metadata.identifierField, variables.id == nil {
                guard let data: SelectorData = environment.lookup(selector: selector!).data else {
                    preconditionFailure("Could not set identifier because fragment data was nil")
                }

                let identifierValue = data.get(String.self, identifierField)
                variables.id = .string(identifierValue)
            }

            refetchOperation = metadata.operation.createDescriptor(variables: variables)
            isRefetchLoaded = false
            refetchKey = UUID()

            load(from: resource, queryResource: queryResource, key: key)
        }
    }

    private func stopRefetchingIfNeeded() {
        if let doneRefetching = doneRefetching {
            doneRefetching()
            self.doneRefetching = nil
        }
    }

}

public protocol Refetching {
    associatedtype RefetchVariables: VariableDataConvertible

    func refetch(_ variables: RefetchVariables?) async
}
