import Combine

public class Environment {
    public private(set) var network: Network
    public private(set) var store: Store

    let handlerProvider: HandlerProvider
    let publishQueue: PublishQueue
    let operationTracker = OperationTracker()

    public init(
        network: Network,
        store: Store,
        handlerProvider: HandlerProvider = DefaultHandlerProvider()) {
        self.network = network
        self.store = store
        self.handlerProvider = handlerProvider

        publishQueue = PublishQueue(store: store, handlerProvider: handlerProvider)
    }
    
    public func fetchQuery<Op: Operation>(_ op: Op) -> AnyPublisher<Op.Data?, Error> {
        precondition(op.node.params.operationKind == .query, "fetchQuery: Expected query operation")
        let operation = op.createDescriptor()
        return execute(operation: operation, cacheConfig: CacheConfig())
            .map { _ in self.lookup(selector: operation.fragment).data }
            .eraseToAnyPublisher()
    }

    public func execute(
        operation: OperationDescriptor,
        cacheConfig: CacheConfig
    ) -> AnyPublisher<GraphQLResponse, Error> {
        let source = network.execute(request: operation.request.node.params,
                                     variables: operation.request.variables,
                                     cacheConfig: cacheConfig)
        let sink = PassthroughSubject<GraphQLResponse, Error>()
        Executor(
            operation: operation,
            operationTracker: operationTracker,
            publishQueue: publishQueue,
            source: source,
            sink: sink
        ).execute()
        return sink.eraseToAnyPublisher()
    }

    public func executeMutation(
        operation: OperationDescriptor,
        cacheConfig: CacheConfig,
        optimisticResponse: [String: Any]? = nil,
        optimisticUpdater: SelectorStoreUpdater? = nil,
        updater: SelectorStoreUpdater? = nil
    ) -> AnyPublisher<GraphQLResponse, Error> {
        let source = network.execute(request: operation.request.node.params,
                                     variables: operation.request.variables,
                                     cacheConfig: cacheConfig)
        let sink = PassthroughSubject<GraphQLResponse, Error>()
        Executor(
            operation: operation,
            operationTracker: operationTracker,
            optimisticResponse: optimisticResponse,
            optimisticUpdater: optimisticUpdater,
            publishQueue: publishQueue,
            source: source,
            sink: sink,
            updater: updater
        ).execute()
        return sink.eraseToAnyPublisher()
    }

    public func lookup<T: Readable>(
        selector: SingularReaderSelector
    ) -> Snapshot<T?> {
        store.lookup(selector: selector)
    }

    public func retain(operation: OperationDescriptor) -> AnyCancellable {
        store.retain(operation: operation)
    }

    public func subscribe<T: Readable>(snapshot: Snapshot<T?>) -> SnapshotPublisher<T> {
        store.subscribe(snapshot: snapshot)
    }

    public func isActive(request: RequestDescriptor) -> Bool {
        operationTracker.isActive(request: request)
    }
}
