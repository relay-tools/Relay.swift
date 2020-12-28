import SwiftUI
import Relay

@propertyWrapper
public struct Mutation<Operation: Relay.Operation>: DynamicProperty {
    @SwiftUI.Environment(\.relayEnvironment) var environment: Relay.Environment?
    @StateObject var tracker = MutationTracker<Operation>()

    public init() {}
    public init(_ type: Operation.Type) {}

    public var wrappedValue: Mutator<Operation> {
        get { Mutator(environment: environment!, tracker: tracker) }
    }

    public struct Mutator<Operation: Relay.Operation> {
        let environment: Relay.Environment
        let tracker: MutationTracker<Operation>

        public func commit(
            variables: Operation.Variables,
            optimisticResponse: [String: Any]? = nil,
            optimisticUpdater: SelectorStoreUpdater? = nil,
            updater: SelectorStoreUpdater? = nil,
            completion: ((Result<Operation.Data?, Error>) -> Void)? = nil
        ) {
            tracker.commit(
                environment: environment,
                variables: variables,
                optimisticResponse: optimisticResponse,
                optimisticUpdater: optimisticUpdater,
                updater: updater,
                completion: completion
            )
        }

        public var isInFlight: Bool {
            tracker.requestsInFlight > 0
        }
    }
}

extension Mutation.Mutator where Operation.Variables == EmptyVariables {
    public func commit(
        optimisticResponse: [String: Any]? = nil,
        optimisticUpdater: SelectorStoreUpdater? = nil,
        updater: SelectorStoreUpdater? = nil
    ) {
        commit(variables: .init(), optimisticResponse: optimisticResponse, optimisticUpdater: optimisticUpdater, updater: updater)
    }
}
