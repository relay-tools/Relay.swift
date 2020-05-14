import SwiftUI
import Relay

@propertyWrapper
public struct Mutation<O: Relay.Operation>: DynamicProperty {
    let operation: O
    @SwiftUI.Environment(\.relayEnvironment) var environment: Relay.Environment?
    @ObservedObject var tracker: MutationTracker<O>

    public init(_ type: O.Type) {
        let op = O()
        operation = op
        tracker = MutationTracker(operation: op)
    }

    public var wrappedValue: Mutator<O> {
        get { Mutator(environment: environment!, tracker: tracker) }
    }

    public struct Mutator<O: Relay.Operation> {
        let environment: Relay.Environment
        let tracker: MutationTracker<O>

        public func commit(
            variables: O.Variables,
            optimisticResponse: [String: Any]? = nil,
            optimisticUpdater: SelectorStoreUpdater? = nil,
            updater: SelectorStoreUpdater? = nil
        ) {
            tracker.commit(
                environment: environment,
                variables: variables,
                optimisticResponse: optimisticResponse,
                optimisticUpdater: optimisticUpdater,
                updater: updater
            )
        }

        public var isInFlight: Bool {
            tracker.requestsInFlight > 0
        }
    }
}

extension Mutation.Mutator where O.Variables == EmptyVariables {
    public func commit(
        optimisticResponse: [String: Any]? = nil,
        optimisticUpdater: SelectorStoreUpdater? = nil,
        updater: SelectorStoreUpdater? = nil
    ) {
        commit(variables: .init(), optimisticResponse: optimisticResponse, optimisticUpdater: optimisticUpdater, updater: updater)
    }
}
