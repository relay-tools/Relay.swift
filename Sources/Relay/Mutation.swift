import Combine

extension Environment {
    /// Execute a mutation to update data on the server.
    ///
    /// Use this to execute a mutation outside the context of one of your SwiftUI views.
    ///
    /// Note that you need to subscribe to the publisher that is returned (using `sink` or `assign`) in order for your mutation to actually execute, and if that subscription is canceled early for some reason, you may not see the updates you expect. If you want to run a mutation in response to input from a SwiftUI view, use the `@Mutation` property wrapper, which manages this for you and makes it easy to show progress state in your UI while the mutation is running.
    ///
    /// To learn more about how to use the `updater` and `optimisticUpdater` parameters, see <doc:Updaters>.
    ///
    /// - Parameters:
    ///    - operation: The mutation to execute.
    ///    - cacheConfig: Cache configuration that will be passed along to your ``Network`` implementation.
    ///    - optimisticResponse: A static response payload to use to temporarily update your app's UI while the mutation is in-flight.
    ///    - optimisticUpdater: An updater function to use to temporarily update your app's UI while the mutation is in-flight.
    ///    - updater: An updater function to use to update the store after the mutation has responded successfully.
    ///
    ///  - Returns: A publisher for the response data returned by the server for the mutation.
    public func commitMutation<Op: Operation>(
        _ operation: Op,
        cacheConfig: CacheConfig = .init(),
        optimisticResponse: [String: Any]? = nil,
        optimisticUpdater: SelectorStoreUpdater? = nil,
        updater: SelectorStoreUpdater? = nil
    ) -> AnyPublisher<Op.Data?, Error> {
        let mutation = operation.node
        precondition(mutation.params.operationKind == .mutation, "commitMutation: Expected mutation operation")

        let operationDesc = operation.createDescriptor(dataID: .generateClientID())

        // TODO declarative configs

        return executeMutation(
            operation: operationDesc,
            cacheConfig: cacheConfig,
            optimisticResponse: optimisticResponse,
            optimisticUpdater: optimisticUpdater,
            updater: updater
        )
            .map { _ in self.lookup(selector: operationDesc.fragment) }
            .map { $0.data }
            .eraseToAnyPublisher()
    }
}
