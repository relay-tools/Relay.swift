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
        updater: SelectorStoreUpdater? = nil,
        completion: ((Result<O.Data?, Error>) -> Void)? = nil
    ) {
        requestsInFlight += 1
        commitMutation(
            environment,
            O(variables: variables),
            optimisticResponse: optimisticResponse,
            optimisticUpdater: optimisticUpdater,
            updater: updater
        ).sink(receiveCompletion: { [weak self] result in
            self?.requestsInFlight -= 1
            
            if case .failure(let error) = result {
                completion?(.failure(error))
            }
        }) { data in
            completion?(.success(data))
        }.store(in: &cancellables)
    }
}
