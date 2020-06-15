import Combine
import Foundation

public class MockEnvironment: Environment {
    private let mockNetwork = MockNetwork()

    public init(handlerProvider: HandlerProvider = DefaultHandlerProvider()) {
        super.init(network: mockNetwork, store: Store(), handlerProvider: handlerProvider)
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

    public func mockResponse<O: Operation>(_ op: O, _ payload: [String: Any]) {
        cachePayload(op, payload)
        
        let identifer = op.createDescriptor().request.identifier
        mockNetwork.mockedResponses[identifer] = payload
    }
}

class MockNetwork: Network {
    var mockedResponses: [RequestIdentifier: [String: Any]] = [:]

    func execute(request: RequestParameters, variables: VariableData, cacheConfig: CacheConfig) -> AnyPublisher<Data, Error> {
        let identifier = request.identifier(variables: variables)
        guard let mockedResponse = mockedResponses[identifier] else {
            return Empty().eraseToAnyPublisher()
        }

        do {
            let data = try JSONSerialization.data(withJSONObject: mockedResponse, options: [])
            return Result.Publisher(.success(data)).eraseToAnyPublisher()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
}
