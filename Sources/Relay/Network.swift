import Combine
import Foundation

public protocol Network {
    func execute(
        request: RequestParameters,
        variables: VariableData,
        cacheConfig: CacheConfig
    ) -> AnyPublisher<Data, Error>
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
