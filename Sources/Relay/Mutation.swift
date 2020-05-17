import Combine

public typealias SelectorStoreUpdater = (RecordSourceSelectorProxy, SelectorData?) -> Void

public func commitMutation<Op: Operation>(
    _ environment: Environment,
    _ operation: Op,
    variables: Op.Variables,
    optimisticResponse: [String: Any]? = nil,
    optimisticUpdater: SelectorStoreUpdater? = nil,
    updater: SelectorStoreUpdater? = nil
) -> AnyPublisher<Op.Data?, Error> {
    let mutation = operation.node
    precondition(mutation.params.operationKind == .mutation, "commitMutation: Expected mutation operation")

    let operationDesc = operation.createDescriptor(variables: variables, dataID: .generateClientID())

    // TODO declarative configs

    return environment.executeMutation(
        operation: operationDesc,
        cacheConfig: CacheConfig(),
        optimisticResponse: optimisticResponse,
        optimisticUpdater: optimisticUpdater,
        updater: updater
    )
        .map { _ in environment.lookup(selector: operationDesc.fragment) }
        .map { $0.data }
        .eraseToAnyPublisher()
}

public func commitMutation<Op: Operation>(
    _ environment: Environment,
    _ operation: Op,
    optimisticResponse: [String: Any]? = nil,
    optimisticUpdater: SelectorStoreUpdater? = nil,
    updater: SelectorStoreUpdater? = nil
) -> AnyPublisher<Op.Data?, Error> where Op.Variables == EmptyVariables {
    commitMutation(
        environment,
        operation,
        variables: .init(),
        optimisticResponse: optimisticResponse,
        optimisticUpdater: optimisticUpdater,
        updater: updater
    )
}
