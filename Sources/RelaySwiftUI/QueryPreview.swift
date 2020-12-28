import SwiftUI
import Relay

public struct QueryPreview<Operation: Relay.Operation, Content: View>: View {
    @Query(Operation.self, fetchPolicy: .storeAndNetwork) var query

    let variables: Operation.Variables
    let content: (Operation.Data) -> Content

    public init(_ operation: Operation, _ content: @escaping (Operation.Data) -> Content) {
        self.variables = operation.variables
        self.content = content
    }

    public var body: some View {
        switch query.get(variables) {
        case .loading:
            Text("Loading query data (did you cache a response for this query?)")
        case .failure(let error):
            Text("Error in query: \(error.localizedDescription)")
        case .success(let data):
            if let data = data {
                content(data)
            } else {
                Text("Query is done loading, but has no data.")
            }
        }
    }
}

struct WithCachedPayload<Operation: Relay.Operation>: ViewModifier {
    let environment: MockEnvironment

    init(_ operation: Operation, resource: String, extension: String = "json", bundle: Bundle = .main) {
        environment = MockEnvironment()
        try! environment.cachePayload(operation, resource: resource, extension: `extension`, bundle: bundle)
    }

    func body(content: Content) -> some View {
        content.relayEnvironment(environment)
    }
}

public extension View {
    func previewPayload<Operation: Relay.Operation>(_ operation: Operation, resource: String, extension: String = "json", bundle: Bundle = .main) -> some View {
        modifier(WithCachedPayload(operation, resource: resource, extension: `extension`, bundle: bundle))
    }
}
