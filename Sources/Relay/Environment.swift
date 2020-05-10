import Combine

public class Environment {
    public private(set) var network: Network
    public private(set) var store: Store

    let handlerProvider: HandlerProvider
    let publishQueue: PublishQueue

    public init(
        network: Network,
        store: Store,
        handlerProvider: HandlerProvider = DefaultHandlerProvider()) {
        self.network = network
        self.store = store
        self.handlerProvider = handlerProvider

        publishQueue = PublishQueue(store: store, handlerProvider: handlerProvider)
    }

    public func execute(
        operation: OperationDescriptor,
        cacheConfig: CacheConfig
    ) -> AnyPublisher<GraphQLResponse, Error> {
        let source = network.execute(request: operation.request.node.params,
                                     variables: operation.request.variables,
                                     cacheConfig: cacheConfig)
        let sink = PassthroughSubject<GraphQLResponse, Error>()
        Executor(operation: operation, publishQueue: publishQueue, source: source, sink: sink).execute()
        return sink.eraseToAnyPublisher()
    }

    public func lookup<T: Readable>(
        selector: SingularReaderSelector
    ) -> Snapshot<T?> {
        store.lookup(selector: selector)
    }

    public func subscribe<T: Readable>(snapshot: Snapshot<T?>) -> SnapshotPublisher<T> {
        store.subscribe(snapshot: snapshot)
    }
}
