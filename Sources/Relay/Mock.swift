import Combine
import Foundation

public class MockEnvironment: Environment {
    public init(handlerProvider: HandlerProvider = DefaultHandlerProvider()) {
        super.init(network: MockNetwork(), store: Store(), handlerProvider: handlerProvider)
    }

    public func cachePayload<O: Operation>(_ op: O, _ payload: [String: Any]) {
        let response = try! GraphQLResponse(dictionary: payload)
        let operation = op.createDescriptor()
        let selector = operation.root
        var recordSource = DefaultRecordSource()
        recordSource[selector.dataID] = Record(dataID: selector.dataID, typename: Record.root.typename)
        let responsePayload = ResponseNormalizer.normalize(
            recordSource: recordSource,
            selector: selector,
            data: response.data!, // TODO handle when there is no data
            request: operation.request)
        publishQueue.commit(payload: responsePayload, operation: operation)
        _ = publishQueue.run()
    }
}

struct MockNetwork: Network {
    func execute(request: RequestParameters, variables: VariableData, cacheConfig: CacheConfig) -> AnyPublisher<Data, Error> {
        return Empty().eraseToAnyPublisher()
    }
}
