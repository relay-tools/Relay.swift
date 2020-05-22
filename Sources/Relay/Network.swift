import Combine
import Foundation

public protocol Network {
    func execute(
        request: RequestParameters,
        variables: VariableData,
        cacheConfig: CacheConfig
    ) -> AnyPublisher<Data, Error>
}
