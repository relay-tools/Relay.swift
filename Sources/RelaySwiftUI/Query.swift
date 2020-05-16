import SwiftUI
import Relay

public enum QueryFetchPolicy {
    case networkOnly
    case storeAndNetwork
}

@propertyWrapper
public struct Query<O: Relay.Operation>: DynamicProperty {
    @SwiftUI.Environment(\.relayEnvironment) var environment
    @ObservedObject var loader: QueryLoader<O>

    public init(_ type: O.Type, fetchPolicy: QueryFetchPolicy = .networkOnly) {
        loader = QueryLoader(op: O(), fetchPolicy: fetchPolicy)
        loader.variables = EmptyVariables() as? O.Variables
    }

    public var projectedValue: O.Variables {
        get { loader.variables! }
        nonmutating set { loader.variables = newValue }
    }

    public var wrappedValue: Result {
        get {
            switch loader.loadIfNeeded(environment: environment) {
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
