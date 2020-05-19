import Combine
import Relay

class MutationTracker<O: Relay.Operation>: ObservableObject {
    init() {}

    var requestsInFlight = 0 {
        willSet {
            self.objectWillChange.send()
        }
    }

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
            O(variables: variables),
            optimisticResponse: optimisticResponse,
            optimisticUpdater: optimisticUpdater,
            updater: updater
        ).sink(receiveCompletion: { [weak self] completion in
            self?.requestsInFlight -= 1
        }) { _ in }.store(in: &cancellables)
    }
}
