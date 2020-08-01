import Foundation
import Combine
import os

#if swift(>=5.3)
@available(iOS 14.0, macOS 10.16, tvOS 14.0, watchOS 7.0, *)
private let logger = Logger(subsystem: "io.github.mjm.Relay", category: "query-resource")
#endif

public enum FetchPolicy: CustomStringConvertible {
    case storeOnly
    case networkOnly
    case storeAndNetwork
    case storeOrNetwork

    func shouldRender(_ availability: OperationAvailability) -> Bool {
        switch (self, availability) {
        case (.networkOnly, _):
            return false
        case (.storeOnly, _):
            return true
        case (_, .available):
            return true
        default:
            return false
        }
    }

    func shouldFetch(_ availability: OperationAvailability) -> Bool {
        switch (self, availability) {
        case (.storeOnly, _):
            return false
        case (.storeOrNetwork, .available):
            return false
        default:
            return true
        }
    }

    public var description: String {
        switch self {
        case .storeOnly: return "store-only"
        case .networkOnly: return "network-only"
        case .storeAndNetwork: return "store-and-network"
        case .storeOrNetwork: return "store-or-network"
        }
    }
}

public class QueryResource {
    public let environment: Environment
    private var cache: [String: CacheEntry] = [:]

    public init(environment: Environment) {
        self.environment = environment
    }

    public func prepare(
        operation: OperationDescriptor,
        cacheConfig: CacheConfig = .init(),
        fetchPolicy: FetchPolicy = .storeOrNetwork,
        cacheKeyBuster: Any? = nil
    ) -> AnyPublisher<Result<QueryResult, Error>?, Never> {
        var cacheKey = operation.cacheKey(fetchPolicy: fetchPolicy)
        if let cacheKeyBuster = cacheKeyBuster {
            cacheKey += "-\(cacheKeyBuster)"
        }

        let cacheEntry = cache[cacheKey] ?? fetchAndSaveQuery(
            cacheKey: cacheKey,
            operation: operation,
            cacheConfig: cacheConfig,
            fetchPolicy: fetchPolicy
        )

        return cacheEntry.$result.eraseToAnyPublisher()
    }

    public func retain(
        _ queryResult: QueryResult
    ) -> AnyCancellable {
        let cacheEntry = getOrCreateCacheEntry(
            cacheKey: queryResult.cacheKey,
            operation: queryResult.operation,
            result: .success(queryResult),
            subscription: nil
        )

        let cancellable = cacheEntry.retain(environment)

        #if swift(>=5.3)
        if #available(iOS 14.0, macOS 10.16, tvOS 14.0, watchOS 7.0, *) {
            logger.debug("Retain:  \(queryResult.operation.request.node.params.name)\(queryResult.operation.request.variables) [\(cacheEntry.id)]")
        }
        #endif

        return cancellable
    }

    private func fetchAndSaveQuery(
        cacheKey: String,
        operation: OperationDescriptor,
        cacheConfig: CacheConfig,
        fetchPolicy: FetchPolicy
    ) -> CacheEntry {
        let availability = environment.check(operation: operation)

        if fetchPolicy.shouldRender(availability) {
            let result = operation.queryResult(for: cacheKey)
            cache[cacheKey] = CacheEntry(
                cacheKey: cacheKey,
                operation: operation,
                result: .success(result),
                onClear: { [weak self] entry in
                    self?.cache.removeValue(forKey: entry.cacheKey)
                }
            )
        }

        if fetchPolicy.shouldFetch(availability) {
            let result = operation.queryResult(for: cacheKey)
            var subscription: AnyCancellable?
            subscription = environment.execute(operation: operation, cacheConfig: cacheConfig)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] completion in
                    guard let self = self else { return }

                    switch completion {
                    case .finished:
                        guard let cacheEntry = self.cache[cacheKey] else { return }

                        subscription = nil
                        cacheEntry.subscription = nil
                    case .failure(let error):
                        let cacheEntry = self.getOrCreateCacheEntry(
                            cacheKey: cacheKey,
                            operation: operation,
                            result: .failure(error),
                            subscription: subscription
                        )

                        subscription = nil
                        cacheEntry.subscription = nil
                        cacheEntry.result = .failure(error)
                    }
                } receiveValue: { [weak self] _ in
                    guard let self = self else { return }
                    let cacheEntry = self.getOrCreateCacheEntry(
                        cacheKey: cacheKey,
                        operation: operation,
                        result: .success(result),
                        subscription: subscription
                    )

                    cacheEntry.result = .success(result)
                }

            if cache[cacheKey] == nil {
                cache[cacheKey] = CacheEntry(
                    cacheKey: cacheKey,
                    operation: operation,
                    subscription: subscription,
                    onClear: { [weak self] entry in
                        self?.cache.removeValue(forKey: entry.cacheKey)
                    }
                )
            }
        }

        let cacheEntry = cache[cacheKey]!

        #if swift(>=5.3)
        if #available(iOS 14.0, macOS 10.16, tvOS 14.0, watchOS 7.0, *) {
            logger.debug("Fetch:  \(operation.request.node.params.name)\(operation.request.variables) [\(fetchPolicy), \(availability), \(cacheEntry.id)]")
        }
        #endif

        return cacheEntry
    }

    private func getOrCreateCacheEntry(
        cacheKey: String,
        operation: OperationDescriptor,
        result: Result<QueryResult, Error>?,
        subscription: AnyCancellable?
    ) -> CacheEntry {
        if let cacheEntry = cache[cacheKey] {
            return cacheEntry
        }

        let cacheEntry = CacheEntry(
            cacheKey: cacheKey,
            operation: operation,
            result: result,
            subscription: subscription,
            onClear: { [weak self] entry in
                self?.cache.removeValue(forKey: entry.cacheKey)
            }
        )
        cache[cacheKey] = cacheEntry
        return cacheEntry
    }

    class CacheEntry {
        let id: UUID
        var cacheKey: String
        var operation: OperationDescriptor
        @Published var result: Result<QueryResult, Error>?
        var subscription: AnyCancellable?
        var onClear: (CacheEntry) -> Void
        var retainCount = 0
        var retainCancellable: AnyCancellable?

        init(
            cacheKey: String,
            operation: OperationDescriptor,
            result: Result<QueryResult, Error>? = nil,
            subscription: AnyCancellable? = nil,
            onClear: @escaping (CacheEntry) -> Void
        ) {
            id = UUID()
            self.cacheKey = cacheKey
            self.operation = operation
            self.result = result
            self.subscription = subscription
            self.onClear = onClear
        }

        func retain(_ environment: Environment) -> AnyCancellable {
            retainCount += 1
            if retainCount == 1 {
                retainCancellable = environment.retain(operation: operation)
            }

            return AnyCancellable {
                self.retainCount -= 1
                if self.retainCount < 1 {
                    self.retainCancellable = nil
                    self.onClear(self)
                }
            }
        }
    }

    public struct QueryResult {
        public var cacheKey: String
        public var fragmentNode: ReaderFragment
        public var fragmentRef: FragmentPointer
        public var operation: OperationDescriptor
    }
}

private extension OperationDescriptor {
    func cacheKey(fetchPolicy: FetchPolicy) -> String {
        "\(fetchPolicy)-\(request.identifier)"
    }

    func queryResult(for cacheKey: String) -> QueryResource.QueryResult {
        QueryResource.QueryResult(
            cacheKey: cacheKey,
            fragmentNode: request.node.fragment,
            fragmentRef: FragmentPointer(
                variables: request.variables,
                id: fragment.dataID,
                owner: request
            ),
            operation: self
        )
    }
}
