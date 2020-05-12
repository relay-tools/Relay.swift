import Combine
import Foundation
import Relay

class QueryLoader<Op: Relay.Operation>: ObservableObject {
    @Published var result: Result<Snapshot<Op.Data?>, Error>?

    var op: Op
    var variables: Op.Variables
    var fetchPolicy: QueryFetchPolicy

    private var environment: Environment!
    private var fetchCancellable: AnyCancellable?
    private var subscribeCancellable: AnyCancellable?

    init(op: Op, variables: Op.Variables, fetchPolicy: QueryFetchPolicy) {
        self.op = op
        self.variables = variables
        self.fetchPolicy = fetchPolicy
    }

    var isLoading: Bool {
        if result == nil {
            return true
        }

        if case .success(let snapshot) = result,
           snapshot.isMissingData,
           environment.isActive(request: snapshot.selector.owner) {
            return true
        }

        return false
    }

    var error: Error? {
        if case .failure(let error) = result {
            return error
        }
        return nil
    }

    var data: Op.Data? {
        if case .success(let snapshot) = result {
            return snapshot.data
        }
        return nil
    }

    func load(environment: Environment?) {
        guard let environment = environment else {
            preconditionFailure("Trying to use a RelayQuery without setting up an Environment")
        }

        self.environment = environment

        let operation = op.createDescriptor(variables: variables)
        lookupIfPossible(operation: operation)

        fetchCancellable = environment.execute(operation: operation, cacheConfig: CacheConfig())
            .receive(on: DispatchQueue.main)
            .map { _ -> Snapshot<Op.Data?> in environment.lookup(selector: operation.fragment) }
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.result = .failure(error)
                }
            }, receiveValue: { [weak self] response in
                self?.result = .success(response)
                self?.subscribe()
            })
    }

    func lookupIfPossible(operation: OperationDescriptor) {
        guard fetchPolicy == .storeAndNetwork else { return }

        let snapshot: Snapshot<Op.Data?> = environment.lookup(selector: operation.fragment)
        if snapshot.data != nil {
            result = .success(snapshot)
            subscribe()
        }
    }

    func subscribe() {
        guard case .success(let snapshot) = result else {
            return
        }

        subscribeCancellable = environment.subscribe(snapshot: snapshot)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newSnapshot in
                self?.result = .success(newSnapshot)
            }
    }
}
