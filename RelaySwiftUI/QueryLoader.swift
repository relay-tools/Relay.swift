import Combine
import Relay

class QueryLoader<Op: Relay.Operation>: ObservableObject {
    @Published var result: Result<Snapshot<Op.Data?>, Error>?

    var op: Op
    var variables: Op.Variables

    private var cancellable: AnyCancellable?

    init(op: Op, variables: Op.Variables) {
        self.op = op
        self.variables = variables
    }

    var isLoading: Bool {
        result == nil
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

        let operation = op.createDescriptor(variables: variables)
        cancellable = environment.execute(operation: operation, cacheConfig: "TODO")
            .map { _ -> Snapshot<Op.Data?> in environment.lookup(selector: operation.fragment) }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.result = .failure(error)
                } else {
                    self?.subscribe(environment: environment)
                }
            }, receiveValue: { [weak self] response in
                self?.result = .success(response)
            })
    }

    func subscribe(environment: Environment) {
        guard case .success(let snapshot) = result else {
            return
        }

        cancellable = environment.subscribe(snapshot: snapshot)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newSnapshot in
                self?.result = .success(newSnapshot)
            }
    }

    func cancel() {
        cancellable = nil
    }
}
