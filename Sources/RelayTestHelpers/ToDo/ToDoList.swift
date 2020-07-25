import Relay

private let userFragment = graphql("""
fragment ToDoList_user on User
    @refetchable(queryName: "ToDoListPaginationQuery")
    @argumentDefinitions(
        count: { type: "Int", defaultValue: 100 }
        cursor: { type: "String" }
    ) {
    todos(first: $count, after: $cursor)
        @connection(key: "ToDoList_todos") {
        edges {
            node {
                id
                ...ToDoItem_todo
            }
        }
    }
}
""")
