import Combine

extension Environment {
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
