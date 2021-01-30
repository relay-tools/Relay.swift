import Relay

private let mutation = graphql("""
mutation RemoveTodoMutation($input: RemoveTodoInput!) {
    removeTodo(input: $input) {
        deletedTodoId @deleteRecord
    }
}
""")

private let edgeMutation = graphql("""
mutation RemoveTodoEdgeMutation($input: RemoveTodoInput!, $connections: [ID!]!) {
    removeTodo(input: $input) {
        deletedTodoId @deleteEdge(connections: $connections)
    }
}
""")

public enum RemoveTodo {
    public static let removeBuyHorse = """
{
  "data": {
    "removeTodo": {
      "deletedTodoId": "VG9kbzox"
    }
  }
}
"""

    public static let error = """
{
    "errors": [{"message": "This is an error that occurred in the mutation."}],
}
"""
}
