import SwiftUI
import Relay

public struct RelayQuery<Op: Relay.Operation, LoadingView: View, ErrorView: View, DataView: View>: View {
    @ObservedObject private var loader: QueryLoader<Op>
    @SwiftUI.Environment(\.relayEnvironment) private var environment: Relay.Environment?

    private let loadingContent: LoadingView
    private let errorContent: (Error) -> ErrorView
    private let dataContent: (Op.Data?) -> DataView

    public init(op: Op,
                variables: Op.Variables,
                loadingContent: LoadingView,
                errorContent: @escaping (Error) -> ErrorView,
                dataContent: @escaping (Op.Data?) -> DataView) {
        self.loader = QueryLoader(op: op, variables: variables)
        self.loadingContent = loadingContent
        self.errorContent = errorContent
        self.dataContent = dataContent
    }

    public var body: some View {
        Group {
            if loader.isLoading {
                loadingContent
                    .onAppear { self.loader.load(environment: self.environment) }
                    .onDisappear { self.loader.cancel() }
            } else if loader.error != nil {
                errorContent(loader.error!)
            } else {
                dataContent(loader.data)
            }
        }
    }
}
