import Combine
import Foundation
import Relay

class RefetchFragmentLoader<Fragment: Relay.RefetchFragment>: ObservableObject, Refetching {
    typealias RefetchVariables = Fragment.Operation.Variables

    let metadata: Fragment.Metadata
    let fragmentLoader: FragmentLoader<Fragment>

    var fragmentLoaderCancellable: AnyCancellable?
    var refetchCancellable: AnyCancellable?

    init() {
        self.metadata = Fragment.metadata
        self.fragmentLoader = FragmentLoader()

//        if #available(iOS 14.0, macOS 10.16, tvOS 14.0, watchOS 7.0, *) {
//            fragmentLoader.$snapshot.assign(to: $snapshot)
//        } else {
            fragmentLoaderCancellable = fragmentLoader.$snapshot.sink { [weak self] newSnapshot in
                self?.snapshot = newSnapshot
            }
//        }
    }

    func load(from environment: Environment, key: Fragment.Key) {
        fragmentLoader.load(from: environment, key: key)
    }

    @Published var snapshot: Snapshot<Fragment.Data?>?

    var data: Fragment.Data? {
        fragmentLoader.data
    }

    var environment: Environment! {
        fragmentLoader.environment
    }

    var selector: SingularReaderSelector? {
        fragmentLoader.selector
    }

    func refetch(_ variables: RefetchVariables?) {
        guard var variables = variables?.variableData ?? selector?.owner.variables else {
            preconditionFailure("Attempting to refetch before the fragment has even been loaded")
        }

        if let identifierField = metadata.identifierField, variables.id == nil {
            guard let data: SelectorData = environment.lookup(selector: selector!).data else {
                preconditionFailure("Could not set identifier because fragment data was nil")
            }

            let identifierValue = data.get(String.self, identifierField)
            variables.id = .string(identifierValue)
        }

        let refetchQuery = metadata.operation.createDescriptor(variables: variables)

        refetchCancellable = environment.execute(operation: refetchQuery, cacheConfig: CacheConfig())
            .receive(on: DispatchQueue.main)
            .map { _ in () }
            .sink(receiveCompletion: { _ in }, receiveValue: {})
    }
}

public protocol Refetching {
    associatedtype RefetchVariables: VariableDataConvertible

    func refetch(_ variables: RefetchVariables?)
}
