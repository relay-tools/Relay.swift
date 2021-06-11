import Combine
import Foundation
import os

private let logger = Logger(subsystem: "io.github.mjm.Relay", category: "environment")

public typealias SelectorStoreUpdater = (inout RecordSourceSelectorProxy, SelectorData?) -> Void
public typealias StoreUpdater = (inout RecordSourceProxy) -> Void

/// A handle for interacting with Relay.
///
/// The environment combines all the things that Relay needs to be able to work. You use an environment to fetch queries and load stored records. Any views in your app that need to use Relay will need access to the environment to do so.
public class Environment {
    public private(set) var network: Network
    public private(set) var store: Store

    let handlerProvider: HandlerProvider
    let publishQueue: PublishQueue
    let operationTracker = OperationTracker()

    /// Create a new Relay environment.
    ///
    /// - Parameters:
    ///    - network: An implementation of ``Network`` that can send queries to your GraphQL API and return the results to Relay.
    ///    - store: The store to use to keep track of locally cached records.
    ///    - handlerProvider: A provider that can customize how to handle storing data for fields annotated with special GraphQL directives. It is uncommon to override the default handler provider.
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

    /// Perform a query without displaying the data in a view.
    ///
    /// Sometimes this can be useful to update the local store with new data in response to an event, or if you need access to a query's data in a background task. If you want to show query data in a SwiftUI view, use the `@Query` property wrapper in `RelaySwiftUI`.
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

    /// Update the store without a server-side mutation.
    ///
    /// Use this to add client-only data to the store. The ``StoreUpdater`` function you pass in is similar to the ``SelectorStoreUpdater`` used for mutations, but without the methods and arguments for information provided by the mutation's response.
    ///
    /// - Parameter updater: An updater function that makes the desired changes to the store's contents.
    public func commitUpdate(_ updater: @escaping StoreUpdater) {
        publishQueue.commit(updater: updater)
        _ = publishQueue.run()
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
        return handleEvents { subscription in
            logger.debug("Execution Start:   \(params.name, privacy: .public)\(variables)")
        } receiveOutput: { data in
            logger.debug("Execution Data:    \(params.name, privacy: .public)\(variables)  (\(data.count) bytes)")
        } receiveCompletion: { completion in
            switch completion {
            case .finished:
                logger.debug("Execution Success: \(params.name, privacy: .public)\(variables)")
            case .failure(let error):
                logger.error("Execution Failure: \(params.name, privacy: .public)\(variables)  \(error as NSError)")
            }
        } receiveCancel: {
            logger.debug("Execution Cancel:  \(params.name, privacy: .public)\(variables)")
        }.eraseToAnyPublisher()
    }
}
