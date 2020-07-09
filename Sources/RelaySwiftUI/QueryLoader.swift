import Combine
import Foundation
import Relay

class QueryLoader<Op: Relay.Operation>: ObservableObject {
    @Published var result: Result<Snapshot<Op.Data?>, Error>? {
        willSet {
            objectWillChange.send()
        }
    }

    var variables: Op.Variables?
    var fetchPolicy: QueryFetchPolicy?
    var fetchKey: String?

    private var environment: Environment!
    private var fetchCancellable: AnyCancellable?
    private var subscribeCancellable: AnyCancellable?
    private var retainCancellable: AnyCancellable?

    init() {}

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

    private var isLoaded = false

    func reload() {
        isLoaded = false
        result = nil

        if self.environment != nil {
            _ = loadIfNeeded(environment: self.environment)
        }
    }

    func loadIfNeeded(
        environment: Environment?,
        variables: Op.Variables? = nil,
        fetchPolicy: QueryFetchPolicy? = nil,
        fetchKey: Any? = nil
    ) -> Result<Snapshot<Op.Data?>, Error>? {
        guard !isLoaded ||
                environment !== self.environment ||
                (fetchPolicy != nil && fetchPolicy != self.fetchPolicy) ||
                (variables != nil && variables?.variableData != self.variables?.variableData) ||
                (fetchKey != nil && String(describing: fetchKey!) != self.fetchKey)
        else {
            return result
        }

        if let environment = environment {
            self.environment = environment
        }

        if let fetchPolicy = fetchPolicy {
            self.fetchPolicy = fetchPolicy
        }

        if let variables = variables {
            self.variables = variables
        }
        
        if let fetchKey = fetchKey {
            let fetchKeyString = String(describing: fetchKey)
            if fetchKeyString != self.fetchKey {
                self.result = nil
                self.fetchKey = fetchKeyString
            }
        }

        guard let environment = self.environment else {
            preconditionFailure("Trying to use a Relay Query without setting up an Environment")
        }
        guard let variables = self.variables else {
            preconditionFailure("Trying to use a Relay Query without setting its variables")
        }

        let operation = Op(variables: variables).createDescriptor()
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

        retainCancellable = environment.retain(operation: operation)

        isLoaded = true
        return result
    }

    func lookupIfPossible(operation: OperationDescriptor) {
        guard fetchPolicy == .storeAndNetwork || environment.forceFetchFromStore else { return }
        guard case .available = environment.check(operation: operation) else {
            result = nil
            return
        }

        let snapshot: Snapshot<Op.Data?> = environment.lookup(selector: operation.fragment)
        if !snapshot.isMissingData {
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
                if !newSnapshot.isMissingData {
                    self?.result = .success(newSnapshot)
                }
            }
    }
}
