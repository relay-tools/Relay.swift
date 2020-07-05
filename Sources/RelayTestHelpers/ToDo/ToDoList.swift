import Relay

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
