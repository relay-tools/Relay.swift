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

    private var queryResource: QueryResource!
    private var fragmentResource: FragmentResource!

    private var resultCancellable: AnyCancellable?
    private var subscribeCancellable: AnyCancellable?
    private var retainCancellable: AnyCancellable?

    private var doneRefetching: (() -> Void)?

    init() {}

    private var environment: Environment! {
        queryResource?.environment
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

    private var isLoaded = false

    func reload() {
        isLoaded = false
        result = nil

        if let resource = self.queryResource,
           let fragmentResource = self.fragmentResource,
           let fetchPolicy = fetchPolicy
        {
            _ = loadIfNeeded(resource: resource, fragmentResource: fragmentResource, fetchPolicy: fetchPolicy)
        }
    }

    func refetch() async {
        await withUnsafeContinuation { (continuation: UnsafeContinuation<Void, Never>) in
            doneRefetching = continuation.resume
            fetchKey = UUID().uuidString
            isLoaded = false

            if let resource = self.queryResource,
               let fragmentResource = self.fragmentResource,
               let fetchPolicy = fetchPolicy
            {
                _ = loadIfNeeded(resource: resource, fragmentResource: fragmentResource, fetchPolicy: fetchPolicy)
            }
        }
    }

    func loadIfNeeded(
        resource: QueryResource,
        fragmentResource: FragmentResource,
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
            return result
        }

        self.queryResource = resource
        self.fragmentResource = fragmentResource
        self.fetchPolicy = fetchPolicy

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

        guard let variables = self.variables else {
            preconditionFailure("Trying to use a Relay Query without setting its variables")
        }

        let operation = Op(variables: variables).createDescriptor()
        resultCancellable = resource.prepare(
            operation: operation,
            fetchPolicy: fetchPolicy,
            cacheKeyBuster: self.fetchKey
        ).sink { [weak self] result in
            guard let self = self else { return }

            switch result {
            case nil:
                if self.doneRefetching == nil {
                    self.result = nil
                }
            case .failure(let error):
                self.result = .failure(error)
                self.stopRefreshingIfNeeded()
            case .success(let queryResult):
                let identifier = queryResult.fragmentNode.identifier(for: queryResult.fragmentRef)
                let fragmentResult: FragmentResource.FragmentResult<Op.Data> =
                    fragmentResource.read(node: queryResult.fragmentNode, ref: queryResult.fragmentRef, identifier: identifier)

                if case .success(let oldSnapshot) = self.result, oldSnapshot == fragmentResult.snapshot {} else {
                    self.result = .success(fragmentResult.snapshot)
                }
                self.retainCancellable = resource.retain(queryResult)
                self.subscribeCancellable = fragmentResource.subscribe(fragmentResult)
                    .sink { [weak self] newSnapshot in
                        if !newSnapshot.isMissingData {
                            self?.result = .success(newSnapshot)
                        }
                    }

                self.stopRefreshingIfNeeded()
            }
        }

        isLoaded = true
        return result
    }

    private func stopRefreshingIfNeeded() {
        if let doneRefreshing = doneRefetching {
            doneRefreshing()
            self.doneRefetching = nil
        }
    }
}
