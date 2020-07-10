import Combine
import Foundation
import Relay

class RefetchFragmentLoader<Fragment: Relay.RefetchFragment>: ObservableObject, Refetching {
    typealias RefetchVariables = Fragment.Operation.Variables

    let metadata: Fragment.Metadata

    var environment: Environment!
    var selector: SingularReaderSelector?

    var snapshot: Snapshot<Fragment.Data?>? {
        // not sure why this is needed instead of using Published.
        // my best guess is it's because it's optional, and that adds indirection to the value.
        willSet {
            self.objectWillChange.send()
        }
    }

    var subscribeCancellable: AnyCancellable?
    var refetchCancellable: AnyCancellable?

    init() {
        self.metadata = Fragment.metadata
    }

    func load(from environment: Environment, key: Fragment.Key) {
        let newSelector = Fragment(key: key).selector
        if newSelector == selector {
            return
        }

        self.environment = environment
        self.selector = newSelector
        snapshot = environment.lookup(selector: newSelector)
        subscribe()
    }

    func subscribe() {
        guard let snapshot = snapshot else { return }

        subscribeCancellable = environment.subscribe(snapshot: snapshot)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] snapshot in
                self?.snapshot = snapshot
            }
    }

    var data: Fragment.Data? {
        guard let snapshot = snapshot else { return nil }

        if snapshot.isMissingData && environment.isActive(request: snapshot.selector.owner) {
            // wait for the request to finish to try to get complete data.
            // this can happen if we are loading query data from the store and we change the
            // query variables, such that some of the records in the tree still exist but not
            // all.
            return nil
        }

        return snapshot.data
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
