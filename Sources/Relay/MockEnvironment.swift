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

    public func cachePayload<O: Operation>(_ op: O, _ payload: String) throws {
        cachePayload(op, try load(payload))
    }

    public func cachePayload<O: Operation>(_ op: O, resource: String, extension: String = "json", bundle: Bundle = .main) throws {
        cachePayload(op, try load(resource: resource, extension: `extension`, bundle: bundle))
    }

    public func mockResponse<O: Operation>(_ op: O, _ payload: [String: Any]) {
        cachePayload(op, payload)
        
        let identifer = op.createDescriptor().request.identifier
        let publisher: AnyPublisher<Data, Error>
        do {
            let data = try JSONSerialization.data(withJSONObject: payload, options: [])
            publisher = Result.Publisher(.success(data)).eraseToAnyPublisher()
        } catch {
            publisher = Fail(error: error).eraseToAnyPublisher()
        }
        mockNetwork.mockedResponses[identifer] = publisher
    }

    public func mockResponse<O: Operation>(_ op: O, _ payload: String) throws {
        mockResponse(op, try load(payload))
    }
    
    public func mockResponse<O: Operation>(_ op: O, resource: String, extension: String = "json", bundle: Bundle = .main) throws {
        mockResponse(op, try load(resource: resource, extension: `extension`, bundle: bundle))
    }

    public func delayMockedResponse<O: Operation>(_ op: O, _ payload: [String: Any]) -> (() -> Void) {
        let identifer = op.createDescriptor().request.identifier
        var advance: (() -> Void)?
        let publisher = Future<Data, Error> { promise in
            advance = {
                do {
                    let data = try JSONSerialization.data(withJSONObject: payload, options: [])
                    promise(.success(data))
                } catch {
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
        mockNetwork.mockedResponses[identifer] = publisher
        return advance!
    }
    
    public func delayMockedResponse<O: Operation>(_ op: O, _ payload: String) throws -> (() -> Void) {
        delayMockedResponse(op, try load(payload))
    }
    
    public func delayMockedResponse<O: Operation>(_ op: O, resource: String, extension: String = "json", bundle: Bundle = .main) throws -> (() -> Void) {
        delayMockedResponse(op, try load(resource: resource, extension: `extension`, bundle: bundle))
    }
    
    private func load(resource: String, extension: String, bundle: Bundle) throws -> [String: Any] {
        let dataFile = bundle.url(forResource: resource, withExtension: `extension`)!
        let contents = try Data(contentsOf: dataFile)
        return try JSONSerialization.jsonObject(with: contents, options: []) as! [String: Any]
    }
    
    private func load(_ contents: String) throws -> [String: Any] {
        return try JSONSerialization.jsonObject(with: contents.data(using: .utf8)!, options: []) as! [String: Any]
    }
    
    private var _forceFetchFromStore = true
    override public var forceFetchFromStore: Bool {
        get { _forceFetchFromStore }
        set { _forceFetchFromStore = newValue }
    }
}

class MockNetwork: Network {
    var mockedResponses: [RequestIdentifier: AnyPublisher<Data, Error>] = [:]

    func execute(request: RequestParameters, variables: VariableData, cacheConfig: CacheConfig) -> AnyPublisher<Data, Error> {
        let identifier = request.identifier(variables: variables)
        guard let mockedResponse = mockedResponses[identifier] else {
            return Empty().eraseToAnyPublisher()
        }

        return mockedResponse
    }
}
