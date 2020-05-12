import Combine
import Foundation

class Executor<Sink: Subject> where Sink.Output == GraphQLResponse, Sink.Failure == Error {
    let operation: OperationDescriptor
    let publishQueue: PublishQueue
    let source: AnyPublisher<Data, Error>
    let sink: Sink

    var cancellable: AnyCancellable?

    init(operation: OperationDescriptor,
         publishQueue: PublishQueue,
         source: AnyPublisher<Data, Error>,
         sink: Sink) {
        self.operation = operation
        self.publishQueue = publishQueue
        self.source = source
        self.sink = sink
    }

    func execute() {
        cancellable = source.tryMap { data -> GraphQLResponse in
            guard let obj = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                throw DecodingError.typeMismatch([String: Any].self, .init(codingPath: [], debugDescription: ""))
            }

            return try GraphQLResponse(dictionary: obj)
        }.receive(on: DispatchQueue.main).tryCompactMap { response in
            try self.handle(response: response)
        }.sink(receiveCompletion: { completion in
            self.sink.send(completion: completion)
            self.cancellable = nil
        }) { response in
            self.sink.send(response)
        }
    }

    private func handle(response: GraphQLResponse) throws -> GraphQLResponse? {
        guard let response = try handleErrorResponse(response) else {
            return nil
        }

        // TODO optimistic responses

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
            throw GraphQLError(message: "No data returned for operation \(operation.request.node.params.name)")
        }

        return response
    }

    private func process(response: GraphQLResponse) -> ResponsePayload {
        let payload = normalize(response: response,
                                selector: operation.root,
                                typeName: Record.root.typename,
                                request: operation.request)

        publishQueue.commit(payload: payload, operation: operation)
        return payload
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

public struct GraphQLResponse {
    public var data: [String: Any]?
    public var errors: [GraphQLError]?
    public var extensions: [String: Any]?

    init(dictionary: [String: Any]) throws {
        if let data = dictionary["data"] {
            guard let data = data as? [String: Any] else {
                throw DecodingError.typeMismatch([String: Any]?.self, .init(codingPath: [], debugDescription: ""))
            }
            self.data = data
        }

        if let errors = dictionary["errors"] {
            // TODO
        }

        if let extensions = dictionary["extensions"] {
            guard let extensions = extensions as? [String: Any] else {
                throw DecodingError.typeMismatch([String: Any]?.self, .init(codingPath: [], debugDescription: ""))
            }
            self.extensions = extensions
        }
    }
}
