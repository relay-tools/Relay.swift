import Combine
import Relay

class MutationTracker<O: Relay.Operation>: ObservableObject {
    let operation: O

    init(operation: O) {
        self.operation = operation
    }

    @Published var requestsInFlight = 0

    var cancellables = Set<AnyCancellable>()

    func commit(
        environment: Environment,
        variables: O.Variables,
        optimisticResponse: [String: Any]? = nil,
        optimisticUpdater: SelectorStoreUpdater? = nil,
        updater: SelectorStoreUpdater? = nil
    ) {
        requestsInFlight += 1
        commitMutation(
            environment,
            operation,
            variables: variables,
            optimisticResponse: optimisticResponse,
            optimisticUpdater: optimisticUpdater,
            updater: updater
        ).sink(receiveCompletion: { [weak self] completion in
            self?.requestsInFlight -= 1
        }) { _ in }.store(in: &cancellables)
    }
}
