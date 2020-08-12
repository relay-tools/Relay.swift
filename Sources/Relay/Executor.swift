import Combine
import Foundation

class Executor {
    let operation: OperationDescriptor
    let operationTracker: OperationTracker
    let publishQueue: PublishQueue
    let source: AnyPublisher<Data, Error>
    let updater: SelectorStoreUpdater?

    var isComplete = false
    var optimisticUpdates: [OptimisticUpdate] = []
    var cancellable: AnyCancellable?

    init(operation: OperationDescriptor,
         operationTracker: OperationTracker,
         optimisticResponse: [String: Any]? = nil,
         optimisticUpdater: SelectorStoreUpdater? = nil,
         publishQueue: PublishQueue,
         source: AnyPublisher<Data, Error>,
         updater: SelectorStoreUpdater? = nil) {
        self.operation = operation
        self.operationTracker = operationTracker
        self.publishQueue = publishQueue
        self.source = source
        self.updater = updater

        DispatchQueue.main.async {
            let wrappedOptimisticResponse = optimisticResponse.map { GraphQLResponse(data: $0) }
            self.process(optimisticResponse: wrappedOptimisticResponse, updater: optimisticUpdater)
        }
    }

    func execute() -> AnyPublisher<GraphQLResponse, Error> {
        operationTracker.start(request: operation.request)

        return source.tryMap { data -> GraphQLResponse in
            guard let obj = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                throw DecodingError.typeMismatch([String: Any].self, .init(codingPath: [], debugDescription: ""))
            }

            return try GraphQLResponse(dictionary: obj)
        }.receive(on: DispatchQueue.main).tryCompactMap { response in
            try self.handle(response: response)
        }.handleEvents(receiveCompletion: { completion in
            self.complete(completion)
        }).eraseToAnyPublisher()
    }

    private func complete(_ completion: Subscribers.Completion<Error>) {
        isComplete = true

        if !optimisticUpdates.isEmpty {
            for update in optimisticUpdates {
                publishQueue.revert(update)
            }
            optimisticUpdates.removeAll()
            _ = publishQueue.run()
        }
        operationTracker.complete(request: operation.request)
    }

    private func handle(response: GraphQLResponse) throws -> GraphQLResponse? {
        guard let response = try handleErrorResponse(response) else {
            return nil
        }

//         TODO optimistic responses from module imports

        _ = process(response: response)
        let updatedOwners = publishQueue.run(sourceOperation: operation)
        operationTracker.update(pendingOperation: operation.request, affectedOwners: Set(updatedOwners))

        return response
    }

    private func handleErrorResponse(_ response: GraphQLResponse) throws -> GraphQLResponse? {
        if response.data == nil && response.errors == nil && response.extensions != nil {
            return nil
        }

        if response.data == nil {
            throw NetworkError(
                errors: response.errors ?? [],
                operation: operation.request.node,
                variables: operation.request.variables)
        }

        return response
    }

    private func process(response: GraphQLResponse) -> ResponsePayload {
        let payload = normalize(response: response,
                                selector: operation.root,
                                typeName: Record.root.typename,
                                request: operation.request)

        publishQueue.commit(payload: payload, operation: operation, updater: updater)
        return payload
    }

    private func process(optimisticResponse response: GraphQLResponse?, updater: SelectorStoreUpdater?) {
        if isComplete {
            return
        }

        precondition(optimisticUpdates.isEmpty, "Only one optimistic response allowed per execute")

        if response == nil && updater == nil {
            return
        }

        if let response = response {
            let payload = normalize(response: response,
                                    selector: operation.root,
                                    typeName: Record.root.typename,
                                    request: operation.request)
            optimisticUpdates.append(OptimisticUpdate(
                operation: operation,
                payload: payload,
                updater: updater
            ))
            // TODO followups from module imports
        } else if let updater = updater {
            optimisticUpdates.append(OptimisticUpdate(
                operation: operation,
                payload: ResponsePayload(
                    errors: nil,
                    fieldPayloads: [],
                    source: DefaultRecordSource(),
                    isFinal: false
                ),
                updater: updater
            ))
        }

        for update in optimisticUpdates {
            publishQueue.apply(update)
        }
        _ = publishQueue.run()
    }

    private func normalize(response: GraphQLResponse,
                           selector: NormalizationSelector,
                           typeName: String,
                           request: RequestDescriptor) -> ResponsePayload {
        var recordSource = DefaultRecordSource()
        recordSource[selector.dataID] = Record(dataID: selector.dataID, typename: typeName)
        var payload = ResponseNormalizer.normalize(recordSource: recordSource,
                                                   selector: selector,
                                                   data: response.data!,
                                                   request: request)
        payload.errors = response.errors
        return payload
    }
}
