import SwiftUI
import Relay

public enum QueryFetchPolicy {
    case networkOnly
    case storeAndNetwork
}

public struct RelayQuery<Op: Relay.Operation, LoadingView: View, ErrorView: View, DataView: View>: View {
    @ObservedObject private var loader: QueryLoader<Op>
    @SwiftUI.Environment(\.relayEnvironment) private var environment: Relay.Environment?

    private let loadingContent: LoadingView
    private let errorContent: (Error) -> ErrorView
    private let dataContent: (Op.Data?) -> DataView

    public init(op: Op,
                variables: Op.Variables,
                fetchPolicy: QueryFetchPolicy = .networkOnly,
                loadingContent: LoadingView,
                errorContent: @escaping (Error) -> ErrorView,
                dataContent: @escaping (Op.Data?) -> DataView) {
        self.loader = QueryLoader(op: op, variables: variables, fetchPolicy: fetchPolicy)
        self.loadingContent = loadingContent
        self.errorContent = errorContent
        self.dataContent = dataContent
    }

    public var body: some View {
        _ = self.loader.loadIfNeeded(environment: self.environment)
        return Group {
            if self.loader.isLoading {
                self.loadingContent
            } else if self.loader.error != nil {
                self.errorContent(self.loader.error!)
            } else {
                self.dataContent(self.loader.data)
            }
        }
    }
}

public extension RelayQuery where Op.Variables == EmptyVariables {
    init(op: Op,
         fetchPolicy: QueryFetchPolicy = .networkOnly,
         loadingContent: LoadingView,
         errorContent: @escaping (Error) -> ErrorView,
         dataContent: @escaping (Op.Data?) -> DataView
    ) {
        self.init(op: op,
                  variables: .init(),
                  fetchPolicy: fetchPolicy,
                  loadingContent: loadingContent,
                  errorContent: errorContent,
                  dataContent: dataContent)
    }
}

@propertyWrapper
public struct Query<O: Relay.Operation>: DynamicProperty {
    @SwiftUI.Environment(\.relayEnvironment) var environment
    @ObservedObject var loader: QueryLoader<O>

    public init(_ type: O.Type, fetchPolicy: QueryFetchPolicy = .networkOnly) {
        loader = QueryLoader(op: O(), fetchPolicy: fetchPolicy)
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
