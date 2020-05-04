import Combine

public class Environment {
    public private(set) var network: Network
    public private(set) var store: Store

    public init(
        network: Network,
        store: Store) {
        self.network = network
        self.store = store
    }

    public func execute<Op: Operation>(
        op: Op,
        variables: Op.Variables
    ) -> AnyPublisher<GraphQLResponse<Op.Response>, Error> {
        let source = network.execute(operation: op, request: op.node.params, variables: variables, cacheConfig: "TODO")
        return Executor(operation: op, source: source).execute()
    }
}
