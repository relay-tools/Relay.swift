import Combine
import Foundation
import os

#if swift(>=5.3)
@available(iOS 14.0, macOS 10.16, tvOS 14.0, watchOS 7.0, *)
private let logger = Logger(subsystem: "io.github.mjm.Relay", category: "environment")
#endif

public class Environment {
    public private(set) var network: Network
    public private(set) var store: Store

    let handlerProvider: HandlerProvider
    let publishQueue: PublishQueue
    let operationTracker = OperationTracker()

    public init(
        network: Network,
        store: Store,
        handlerProvider: HandlerProvider = DefaultHandlerProvider()
    ) {
        self.network = network
        self.store = store
        self.handlerProvider = handlerProvider

        publishQueue = PublishQueue(store: store, handlerProvider: handlerProvider)
    }
    
    public func fetchQuery<Op: Operation>(
        _ op: Op,
        cacheConfig: CacheConfig = .init()
    ) -> AnyPublisher<Op.Data?, Error> {
        precondition(op.node.params.operationKind == .query, "fetchQuery: Expected query operation")
        let operation = op.createDescriptor()
        return execute(operation: operation, cacheConfig: cacheConfig)
            .map { _ in self.lookup(selector: operation.fragment).data }
            .eraseToAnyPublisher()
    }

    public func execute(
        operation: OperationDescriptor,
        cacheConfig: CacheConfig = .init()
    ) -> AnyPublisher<GraphQLResponse, Error> {
        let source = network.execute(
            request: operation.request.node.params,
            variables: operation.request.variables,
            cacheConfig: cacheConfig
        ).logExecution(params: operation.request.node.params, variables: operation.request.variables)

        return Executor(
            operation: operation,
            operationTracker: operationTracker,
            publishQueue: publishQueue,
            source: source
        ).execute()
    }

    public func executeMutation(
        operation: OperationDescriptor,
        cacheConfig: CacheConfig = .init(),
        optimisticResponse: [String: Any]? = nil,
        optimisticUpdater: SelectorStoreUpdater? = nil,
        updater: SelectorStoreUpdater? = nil
    ) -> AnyPublisher<GraphQLResponse, Error> {
        var realCacheConfig = cacheConfig
        realCacheConfig.force = true // mutations should always skip a response cache

        let source = network.execute(
            request: operation.request.node.params,
            variables: operation.request.variables,
            cacheConfig: realCacheConfig
        ).logExecution(params: operation.request.node.params, variables: operation.request.variables)

        return Executor(
            operation: operation,
            operationTracker: operationTracker,
            optimisticResponse: optimisticResponse,
            optimisticUpdater: optimisticUpdater,
            publishQueue: publishQueue,
            source: source,
            updater: updater
        ).execute()
    }

    public func lookup<T: Decodable>(
        selector: SingularReaderSelector
    ) -> Snapshot<T?> {
        store.lookup(selector: selector)
    }

    public func check(operation: OperationDescriptor) -> OperationAvailability {
        store.check(operation: operation)
    }

    public func retain(operation: OperationDescriptor) -> AnyCancellable {
        store.retain(operation: operation)
    }

    public func subscribe<T: Decodable>(snapshot: Snapshot<T?>) -> SnapshotPublisher<T> {
        store.subscribe(snapshot: snapshot)
    }

    public func isActive(request: RequestDescriptor) -> Bool {
        operationTracker.isActive(request: request)
    }
    
    public var forceFetchFromStore: Bool {
        false
    }
}

private extension Publisher where Output == Data, Failure == Error {
    func logExecution(params: RequestParameters, variables: VariableData) -> AnyPublisher<Data, Error> {
        #if swift(>=5.3)
        return handleEvents { subscription in
            if #available(iOS 14.0, macOS 10.16, tvOS 14.0, watchOS 7.0, *) {
                logger.debug("Execution Start:   \(params.name, privacy: .public)\(variables)")
            }
        } receiveOutput: { data in
            if #available(iOS 14.0, macOS 10.16, tvOS 14.0, watchOS 7.0, *) {
                logger.debug("Execution Data:    \(params.name, privacy: .public)\(variables)  (\(data.count) bytes)")
            }
        } receiveCompletion: { completion in
            if #available(iOS 14.0, macOS 10.16, tvOS 14.0, watchOS 7.0, *) {
                switch completion {
                case .finished:
                    logger.debug("Execution Success: \(params.name, privacy: .public)\(variables)")
                case .failure(let error):
                    logger.error("Execution Failure: \(params.name, privacy: .public)\(variables)  \(error as NSError)")
                }
            }
        } receiveCancel: {
            if #available(iOS 14.0, macOS 10.16, tvOS 14.0, watchOS 7.0, *) {
                logger.debug("Execution Cancel:  \(params.name, privacy: .public)\(variables)")
            }
        }.eraseToAnyPublisher()
        #else
        return self.eraseToAnyPublisher()
        #endif
    }
}
