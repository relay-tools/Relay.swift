import SwiftUI
import Relay

public typealias QueryFetchPolicy = Relay.FetchPolicy

@propertyWrapper
public struct Query<O: Relay.Operation>: DynamicProperty {
    @SwiftUI.Environment(\.queryResource) var queryResource
    @SwiftUI.Environment(\.fragmentResource) var fragmentResource
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
        let query: Query<O>

        public func get(_ variables: O.Variables, fetchKey: Any? = nil) -> Result {
            switch query.loader.loadIfNeeded(
                resource: query.queryResource!,
                fragmentResource: query.fragmentResource!,
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

extension Query.WrappedValue where O.Variables == EmptyVariables {
    public func get(fetchKey: Any? = nil) -> Query.Result {
        get(.init(), fetchKey: fetchKey)
    }
}
