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
    @Fragment(ToDoItem_todo.self) var todo

    @Mutation(ChangeTodoStatusMutation.self) var changeStatus

    @State private var error: Error?

    init(todo: ToDoItem_todo_Key) {
        $todo = todo
    }

    var body: some View {
        Group {
            if todo != nil {
                HStack {
                    Button(action: {
                        self.changeStatus.commit(
                            id: self.todo!.id,
                            complete: !self.todo!.complete,
                            onError: { self.error = $0 }
                        )
                    }) {
                        Image(systemName: todo!.complete ? "checkmark.square" : "square")
                    }
                        .buttonStyle(BorderlessButtonStyle())
                        .disabled(changeStatus.isInFlight)
                        .alert(isPresented: .constant(error != nil)) {
                            Alert(
                                title: Text("Could Not Toggle Todo"),
                                message: Text(error?.localizedDescription ?? ""),
                                dismissButton: .cancel(Text("Dismiss")) {
                                    self.error = nil
                                }
                            )
                        }

                    Text(verbatim: todo!.text)
                }
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
            List(data.user!.todos!.edges!.map { $0!.node! }, id: \.id) { todoItem in
                ToDoItem(todo: todoItem)
            }
        }
        .previewPayload(op, resource: "ToDoItemPreview")
    }
}
