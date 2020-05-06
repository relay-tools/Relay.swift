import Combine
import Relay

class QueryLoader<Op: Relay.Operation>: ObservableObject {
    @Published var response: GraphQLResponse<Op.Response>?

    var op: Op
    var variables: Op.Variables

    private var cancellable: AnyCancellable?

    init(op: Op, variables: Op.Variables) {
        self.op = op
        self.variables = variables
    }

    var error: Error? {
        response?.errors?.first
    }

    var data: Op.Response? {
        response?.data
    }

    func load(environment: Environment?) {
        guard let environment = environment else {
            preconditionFailure("Trying to use a RelayQuery without setting up an Environment")
        }

        let operation = op.createDescriptor(variables: variables)
        cancellable = environment.execute(operation: operation, cacheConfig: "TODO")
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.response = GraphQLResponse(errors: [GraphQLError(message: error.localizedDescription)])
                }
            }, receiveValue: { [weak self] response in
                self?.response = response
            })
    }

    func cancel() {
        cancellable?.cancel()
    }

    deinit {
        cancel()
    }
}
