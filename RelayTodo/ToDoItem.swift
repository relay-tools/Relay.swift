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
                            complete: !self.todo!.complete
                        )
                    }) {
                        Image(systemName: todo!.complete ? "checkmark.square" : "square")
                    }
                        .buttonStyle(BorderlessButtonStyle())
                        .disabled(changeStatus.isInFlight)

                    Text(verbatim: todo!.text)
                }
            }
        }
    }
}
