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

    public func execute(
        operation: OperationDescriptor,
        cacheConfig: CacheConfig
    ) -> AnyPublisher<GraphQLResponse, Error> {
        let source = network.execute(request: operation.request.node.params,
                                     variables: operation.request.variables,
                                     cacheConfig: cacheConfig)
        let sink = PassthroughSubject<GraphQLResponse, Error>()
        Executor(operation: operation, source: source, sink: sink).execute()
        return sink.eraseToAnyPublisher()
    }
}
