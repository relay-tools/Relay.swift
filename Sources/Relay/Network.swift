import Combine
import Foundation

public protocol Network {
    func execute(
        request: RequestParameters,
        variables: VariableData,
        cacheConfig: CacheConfig
    ) -> AnyPublisher<Data, Error>
}

public struct AnyEncodable: Encodable {
    private let encode: (Encoder) throws -> Void
    public init<T: Encodable>(_ wrapped: T) {
        self.encode = wrapped.encode
    }

    public func encode(to encoder: Encoder) throws {
        try encode(encoder)
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
