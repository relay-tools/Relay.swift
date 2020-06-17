import SwiftUI
import Relay

public struct QueryPreview<Operation: Relay.Operation, Content: View>: View {
    @Query(Operation.self, fetchPolicy: .storeAndNetwork) var query

    let content: (Operation.Data) -> Content

    public init(_ operation: Operation, _ content: @escaping (Operation.Data) -> Content) {
        self.content = content
        $query = operation.variables
    }

    public var body: some View {
        Group {
            if query.isLoading {
                Text("Loading query data (did you cache a response for this query?)")
            } else if query.error != nil {
                Text("Error in query: \(query.error!.localizedDescription)")
            } else if query.data == nil {
                Text("Query is done loading, but has no data.")
            } else {
                content(query.data!)
            }
        }
    }
}