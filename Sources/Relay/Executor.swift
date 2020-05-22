import Combine
import Foundation

class Executor<Sink: Subject> where Sink.Output == GraphQLResponse, Sink.Failure == Error {
    let operation: OperationDescriptor
    let operationTracker: OperationTracker
    let publishQueue: PublishQueue
    let source: AnyPublisher<Data, Error>
    let sink: Sink
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
         sink: Sink,
         updater: SelectorStoreUpdater? = nil) {
        self.operation = operation
        self.operationTracker = operationTracker
        self.publishQueue = publishQueue
        self.source = source
        self.sink = sink
        self.updater = updater

        DispatchQueue.main.async {
            let wrappedOptimisticResponse = optimisticResponse.map { GraphQLResponse(data: $0) }
            self.process(optimisticResponse: wrappedOptimisticResponse, updater: optimisticUpdater)
        }
    }

    func execute() {
        operationTracker.start(request: operation.request)

        cancellable = source.tryMap { data -> GraphQLResponse in
            guard let obj = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                throw DecodingError.typeMismatch([String: Any].self, .init(codingPath: [], debugDescription: ""))
            }

            return try GraphQLResponse(dictionary: obj)
        }.receive(on: DispatchQueue.main).tryCompactMap { response in
            try self.handle(response: response)
        }.sink(receiveCompletion: { completion in
            self.complete(completion)
        }) { response in
            self.sink.send(response)
        }
    }

    private func complete(_ completion: Subscribers.Completion<Error>) {
        isComplete = true

        operationTracker.complete(request: operation.request)
        if !optimisticUpdates.isEmpty {
            for update in optimisticUpdates {
                publishQueue.revert(update)
            }
            optimisticUpdates.removeAll()
            _ = publishQueue.run()
        }

        // TODO complete in operation tracker

        sink.send(completion: completion)
    }

    private func handle(response: GraphQLResponse) throws -> GraphQLResponse? {
        guard let response = try handleErrorResponse(response) else {
            return nil
        }

//         TODO optimistic responses from module imports

        _ = process(response: response)
        let updatedOwners = publishQueue.run(sourceOperation: operation)
        // TODO update operation tracker

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

public struct NetworkError: LocalizedError {
    public var errors: [GraphQLError]
    public var operation: ConcreteRequest
    public var variables: VariableData

    public var localizedDescription: String {
        "Network Operation Failed"
    }

    public var failureReason: String? {
        if errors.isEmpty {
            return "No data or errors returned for operation `\(operation.params.name)`"
        } else {
            return "No data returned for operation `\(operation.params.name)`, got \(errors.count == 1 ? "error" : "\(errors.count) errors"):\n" + errors.map { $0.message }.joined(separator: "\n")
        }
    }
}

public struct GraphQLResponse {
    public var data: [String: Any]?
    public var errors: [GraphQLError]?
    public var extensions: [String: Any]?

    init(data: [String: Any]? = nil, errors: [GraphQLError]? = nil, extensions: [String: Any]? = nil) {
        self.data = data
        self.errors = errors
        self.extensions = extensions
    }

    init(dictionary: [String: Any]) throws {
        if let data = dictionary["data"] {
            guard let data = data as? [String: Any] else {
                throw DecodingError.typeMismatch([String: Any]?.self, .init(codingPath: [], debugDescription: ""))
            }
            self.data = data
        }

        if let errors = dictionary["errors"] {
            guard let errors = errors as? [[String: Any]] else {
                throw DecodingError.typeMismatch([[String: Any]]?.self, .init(codingPath: [], debugDescription: ""))
            }

            self.errors = try errors.map { error in
                guard let error = GraphQLError(dictionary: error) else {
                    throw DecodingError.typeMismatch([String: Any]?.self, .init(codingPath: [], debugDescription: ""))
                }
                return error
            }
        }

        if let extensions = dictionary["extensions"] {
            guard let extensions = extensions as? [String: Any] else {
                throw DecodingError.typeMismatch([String: Any]?.self, .init(codingPath: [], debugDescription: ""))
            }
            self.extensions = extensions
        }
    }
}

public struct GraphQLError: LocalizedError {
    public var message: String

    public init(message: String) {
        self.message = message
    }

    init?(dictionary data: [String: Any]) {
        guard let message = data["message"] as? String else {
            return nil
        }

        self.message = message
    }

    public var errorDescription: String? {
        return message
    }
}

class OperationTracker {
    var inflightOperationIDs = Set<String>()

    func start(request: RequestDescriptor) {
        inflightOperationIDs.insert(request.identifier)
    }

    func complete(request: RequestDescriptor) {
        inflightOperationIDs.remove(request.identifier)
    }

    func isActive(request: RequestDescriptor) -> Bool {
        inflightOperationIDs.contains(request.identifier)
    }
}

struct OptimisticUpdate: Hashable {
    let id: UUID

    var operation: OperationDescriptor
    var payload: ResponsePayload
    var updater: SelectorStoreUpdater?

    init(operation: OperationDescriptor, payload: ResponsePayload, updater: SelectorStoreUpdater?) {
        self.id = UUID()
        self.operation = operation
        self.payload = payload
        self.updater = updater
    }

    static func ==(lhs: OptimisticUpdate, rhs: OptimisticUpdate) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
