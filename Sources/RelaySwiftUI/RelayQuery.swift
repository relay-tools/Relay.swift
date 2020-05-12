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
        Group {
            if self.loader.isLoading {
                self.loadingContent
            } else if self.loader.error != nil {
                self.errorContent(self.loader.error!)
            } else {
                self.dataContent(self.loader.data)
            }
        }
        .onAppear { self.loader.load(environment: self.environment) }
    }
}
