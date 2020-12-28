import SwiftUI
import RelaySwiftUI

private let todoFragment = graphql("""
fragment ToDoItem_todo on Todo {
    id
    text
    complete
}
""")

struct ToDoItem: View {
    @Fragment<ToDoItem_todo> var todo

    @Mutation<ChangeTodoStatusMutation> var changeStatus

    @State private var error: Error?

    var body: some View {
        if let todo = todo {
            HStack {
                Button(action: {
                    changeStatus.commit(
                        id: todo.id,
                        complete: !todo.complete,
                        onError: { error = $0 }
                    )
                }) {
                    Image(systemName: todo.complete ? "checkmark.square" : "square")
                }
                .buttonStyle(BorderlessButtonStyle())
                .disabled(changeStatus.isInFlight)
                .alert(isPresented: .constant(error != nil)) {
                    Alert(
                        title: Text("Could Not Toggle Todo"),
                        message: Text(error?.localizedDescription ?? ""),
                        dismissButton: .cancel(Text("Dismiss")) {
                            error = nil
                        }
                    )
                }

                Text(verbatim: todo.text)
            }
        }
    }
}

private let previewQuery = graphql("""
query ToDoItemPreviewQuery {
    user(id: "me") {
        todos(first: 3) {
            edges {
                node {
                    id
                    ...ToDoItem_todo
                }
            }
        }
    }
}
""")

struct ToDoItem_Previews: PreviewProvider {
    static let op = ToDoItemPreviewQuery()

    static var previews: some View {
        QueryPreview(op) { data in
            List(data.user!.todos!.edges!.map { $0!.node! }) { todoItem in
                ToDoItem(todo: todoItem.asFragment())
            }
        }
        .previewPayload(op, resource: "ToDoItemPreview")
    }
}
