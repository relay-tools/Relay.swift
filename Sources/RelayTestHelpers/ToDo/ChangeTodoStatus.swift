import Relay

private let mutation = graphql("""
mutation ChangeTodoStatusMutation($input: ChangeTodoStatusInput!) {
    changeTodoStatus(input: $input) {
        todo {
            id
            complete
        }
    }
}
""")
