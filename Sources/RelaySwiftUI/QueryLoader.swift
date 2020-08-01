import Combine
import Foundation
import Relay

class QueryLoader<Op: Relay.Operation>: ObservableObject {
    @Published var result: Result<QueryResource.QueryResult, Error>? {
        willSet {
            objectWillChange.send()
        }
    }
    @Published var snapshotResult: Result<Snapshot<Op.Data?>, Error>?

    var variables: Op.Variables?
    var fetchPolicy: QueryFetchPolicy?
    var fetchKey: String?

    private var queryResource: QueryResource!
    private var resultCancellable: AnyCancellable?
    private var fetchCancellable: AnyCancellable?
    private var subscribeCancellable: AnyCancellable?
    private var retainCancellable: AnyCancellable?

    init() {}

    private var environment: Environment! {
        queryResource?.environment
    }

    var isLoading: Bool {
        if snapshotResult == nil {
            return true
        }

        if case .success(let snapshot) = snapshotResult,
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
        if case .success(let snapshot) = snapshotResult {
            return snapshot.data
        }
        return nil
    }

    private var isLoaded = false

    func reload() {
        isLoaded = false
        result = nil
        snapshotResult = nil

        if let resource = self.queryResource, let fetchPolicy = fetchPolicy {
            _ = loadIfNeeded(resource: resource, fetchPolicy: fetchPolicy)
        }
    }

    func loadIfNeeded(
        resource: QueryResource?,
        variables: Op.Variables? = nil,
        fetchPolicy: QueryFetchPolicy,
        fetchKey: Any? = nil
    ) -> Result<Snapshot<Op.Data?>, Error>? {
        guard !isLoaded ||
                resource !== self.queryResource ||
                fetchPolicy != self.fetchPolicy ||
                (variables != nil && variables?.variableData != self.variables?.variableData) ||
                (fetchKey != nil && String(describing: fetchKey!) != self.fetchKey)
        else {
            return snapshotResult
        }

        if let resource = resource {
            self.queryResource = resource
        }

        self.fetchPolicy = fetchPolicy

        if let variables = variables {
            self.variables = variables
        }
        
        if let fetchKey = fetchKey {
            let fetchKeyString = String(describing: fetchKey)
            if fetchKeyString != self.fetchKey {
                self.result = nil
                self.snapshotResult = nil
                self.fetchKey = fetchKeyString
            }
        }

        guard let resource = self.queryResource else {
            preconditionFailure("Trying to use a Relay Query without setting up an Environment")
        }
        guard let variables = self.variables else {
            preconditionFailure("Trying to use a Relay Query without setting its variables")
        }

        let operation = Op(variables: variables).createDescriptor()
        resultCancellable = resource.prepare(
            operation: operation,
            fetchPolicy: fetchPolicy,
            cacheKeyBuster: fetchKey
        ).sink { [weak self] result in
            guard let self = self else { return }

            self.result = result
            self.snapshotResult = result?.map { queryResult -> Snapshot<Op.Data?> in
                let selector = SingularReaderSelector(fragment: queryResult.fragmentNode, pointer: queryResult.fragmentRef)
                return resource.environment.lookup(selector: selector)
            }

            if case .success(let queryResult)? = result {
                self.retainCancellable = self.queryResource.retain(queryResult)
            }

            if case .success(let snapshot) = self.snapshotResult  {
                self.subscribeCancellable = self.environment.subscribe(snapshot: snapshot)
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] newSnapshot in
                        if !newSnapshot.isMissingData {
                            self?.snapshotResult = .success(newSnapshot)
                        }
                    }
            }
        }

        isLoaded = true
        return snapshotResult
    }
}
