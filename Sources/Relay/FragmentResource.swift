import Combine
import Foundation

public class FragmentResource {
    public let environment: Environment
    private var cache: [String: _FragmentResult] = [:]

    public init(environment: Environment) {
        self.environment = environment
    }

    public func read<T: Decodable>(
        node: ReaderFragment,
        ref: FragmentPointer,
        identifier: String
    ) -> FragmentResult<T> {
        let selector = SingularReaderSelector(fragment: node, pointer: ref)
        return read(selector: selector, identifier: identifier)
    }

    public func read<T: Decodable>(
        selector: SingularReaderSelector,
        identifier: String
    ) -> FragmentResult<T> {
        if let cachedValue = cache[identifier] {
            return FragmentResult(inner: cachedValue)
        }

        let snapshot: Snapshot<T?> = environment.lookup(selector: selector)
        if !snapshot.isMissingData {
            let result = _FragmentResult(cacheKey: identifier, snapshot: snapshot)
            cache[identifier] = result
            return FragmentResult(inner: result)
        }

        // TODO track in-flight queries and return a publisher to update when the query finishes

        let result = _FragmentResult(cacheKey: identifier, snapshot: snapshot)
        return FragmentResult(inner: result)
    }

    public func subscribe<T: Decodable>(_ result: FragmentResult<T>) -> AnyPublisher<Snapshot<T?>, Never> {
        environment.subscribe(snapshot: result.snapshot)
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveCancel: { [weak self] in
                self?.cache.removeValue(forKey: result.cacheKey)
            })
            .eraseToAnyPublisher()
    }

    struct _FragmentResult {
        var cacheKey: String
        var snapshot: Any
    }

    public struct FragmentResult<T: Decodable> {
        var inner: _FragmentResult

        var cacheKey: String {
            inner.cacheKey
        }

        public var snapshot: Snapshot<T?> {
            return (inner.snapshot as! Snapshot<T?>)
        }

        public var data: T? {
            snapshot.data
        }
    }
}

