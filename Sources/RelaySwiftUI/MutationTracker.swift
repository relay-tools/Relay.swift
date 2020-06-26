import Combine
import Relay

class MutationTracker<O: Relay.Operation>: ObservableObject {
    init() {}

    var requestsInFlight = 0 {
        willSet {
            self.objectWillChange.send()
        }
    }

    func commit(
        environment: Environment,
        variables: O.Variables,
        optimisticResponse: [String: Any]? = nil,
        optimisticUpdater: SelectorStoreUpdater? = nil,
        updater: SelectorStoreUpdater? = nil,
        completion: ((Result<O.Data?, Error>) -> Void)? = nil
    ) {
        requestsInFlight += 1

        var cancellable: AnyCancellable?
        cancellable = environment.commitMutation(
            O(variables: variables),
            optimisticResponse: optimisticResponse,
            optimisticUpdater: optimisticUpdater,
            updater: updater
        ).sink(receiveCompletion: { [weak self] result in
            self?.requestsInFlight -= 1
            
            if case .failure(let error) = result {
                completion?(.failure(error))
            }

            cancellable?.cancel()
        }) { data in
            completion?(.success(data))
        }
    }
}
