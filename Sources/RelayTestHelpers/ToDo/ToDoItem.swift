import Relay

private let todoFragment = graphql("""
fragment ToDoItem_todo on Todo {
    id
    text
    complete
}
""")
