import Relay

private let query = graphql("""
query CurrentUserToDoListQuery {
    user(id: "me") {
        id
        ...ToDoList_user
    }
}
""")
