import Combine

public protocol Network {
    // TODO define parameter types better
    func execute<Op: Operation>(
        operation: Op,
        request: RequestParameters,
        variables: Op.Variables,
        cacheConfig: CacheConfig
    ) -> AnyPublisher<GraphQLResponse<Op.Response>, Error>
}

// TODO replace with a real type
public typealias CacheConfig = Any

public struct AnyEncodable: Encodable {
    private let encode: (Encoder) throws -> Void
    public init<T: Encodable>(_ wrapped: T) {
        self.encode = wrapped.encode
    }

    public func encode(to encoder: Encoder) throws {
        try encode(encoder)
    }
}

public protocol Operation {
    var node: ConcreteRequest { get }
    associatedtype Variables: Encodable
    associatedtype Response: Decodable
}

public struct GraphQLResponse<Data: Decodable>: Decodable {
    public var data: Data?
    public var errors: [GraphQLError]?

    public init(data: Data? = nil, errors: [GraphQLError]? = nil) {
        self.data = data
        self.errors = errors
    }
}

public struct GraphQLError: LocalizedError, Decodable {
    public var message: String

    public init(message: String) {
        self.message = message
    }

    public var errorDescription: String? {
        return message
    }
}
