import SwiftUI
import Relay

public typealias QueryFetchPolicy = Relay.FetchPolicy

@propertyWrapper
public struct Query<O: Relay.Operation>: DynamicProperty {
    @SwiftUI.Environment(\.queryResource) var queryResource
    @ObservedObject var loader: QueryLoader<O>
    let fetchPolicy: QueryFetchPolicy

    public init(_ type: O.Type, fetchPolicy: QueryFetchPolicy = .networkOnly) {
        self.fetchPolicy = fetchPolicy
        loader = QueryLoader()
        loader.variables = EmptyVariables() as? O.Variables
    }

    public var projectedValue: O.Variables {
        get { loader.variables! }
        nonmutating set {
            loader.variables = newValue
            loader.reload()
        }
    }

    public var wrappedValue: Result {
        get {
            switch loader.loadIfNeeded(resource: queryResource, fetchPolicy: fetchPolicy) {
            case nil:
                return .loading
            case .failure(let error):
                return .failure(error)
            case .success:
                if let data = loader.data {
                    return .success(data)
                } else {
                    return .loading
                }
            }
        }
    }

    public enum Result {
        case loading
        case failure(Error)
        case success(O.Data?)

        public var isLoading: Bool {
            if case .loading = self {
                return true
            }
            return false
        }

        public var error: Error? {
            if case .failure(let error) = self {
                return error
            }
            return nil
        }

        public var data: O.Data? {
            if case .success(let data) = self {
                return data
            }
            return nil
        }
    }
}

#if swift(>=5.3)
@available(iOS 14.0, macOS 10.16, tvOS 14.0, watchOS 7.0, *)
@propertyWrapper
public struct QueryNext<O: Relay.Operation>: DynamicProperty {
    @SwiftUI.Environment(\.queryResource) var queryResource
    @StateObject var loader = QueryLoader<O>()

    let fetchPolicy: QueryFetchPolicy
    
    public init(fetchPolicy: QueryFetchPolicy = .networkOnly) {
        self.fetchPolicy = fetchPolicy
    }

    public init(_ type: O.Type, fetchPolicy: QueryFetchPolicy = .networkOnly) {
        self.init(fetchPolicy: fetchPolicy)
    }

    public var wrappedValue: WrappedValue {
        WrappedValue(query: self)
    }

    public struct WrappedValue {
        let query: QueryNext<O>

        public func get(_ variables: O.Variables, fetchKey: Any? = nil) -> Result {
            switch query.loader.loadIfNeeded(
                resource: query.queryResource,
                variables: variables,
                fetchPolicy: query.fetchPolicy,
                fetchKey: fetchKey
            ) {
            case nil:
                return .loading
            case .failure(let error):
                return .failure(error)
            case .success:
                if let data = query.loader.data {
                    return .success(data)
                } else {
                    return .loading
                }
            }
        }
    }

    public enum Result {
        case loading
        case failure(Error)
        case success(O.Data?)

        public var isLoading: Bool {
            if case .loading = self {
                return true
            }
            return false
        }

        public var error: Error? {
            if case .failure(let error) = self {
                return error
            }
            return nil
        }

        public var data: O.Data? {
            if case .success(let data) = self {
                return data
            }
            return nil
        }
    }
}

@available(iOS 14.0, macOS 10.16, tvOS 14.0, watchOS 7.0, *)
extension QueryNext.WrappedValue where O.Variables == EmptyVariables {
    public func get(fetchKey: Any? = nil) -> QueryNext.Result {
        get(.init(), fetchKey: fetchKey)
    }
}
#endif
