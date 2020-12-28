import SwiftUI
import RelaySwiftUI

private let userFragment = graphql("""
fragment ToDoList_user on User {
  todos(first: 100) {
        edges {
            node {
                id
                ...ToDoItem_todo
            }
        }
    }
}
""")

struct ToDoList: View {
    @Fragment<ToDoList_user> var user

    // Nesting data causes nested types.
    // The names are based on the schema type name and the field name, to avoid
    // creating conflicting types.
    var itemNodes: [ToDoList_user.Data.TodoConnection_todos.TodoEdge_edges.Todo_node] {
        user?.todos?.edges?.compactMap { $0?.node } ?? []
    }

    var body: some View {
        List(itemNodes) { todo in
            ToDoItem(todo: todo.asFragment())
        }
    }
}
