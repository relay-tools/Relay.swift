import Relay

private let appendEdgeMutation = graphql("""
mutation AddTodoAppendEdgeMutation($input: AddTodoInput!, $connections: [ID!]!) {
    addTodo(input: $input) {
        todoEdge @appendEdge(connections: $connections) {
            cursor
            node {
                id
                text
                complete
            }
        }
    }
}
""")

private let prependEdgeMutation = graphql("""
mutation AddTodoPrependEdgeMutation($input: AddTodoInput!, $connections: [ID!]!) {
    addTodo(input: $input) {
        todoEdge @prependEdge(connections: $connections) {
            cursor
            node {
                id
                text
                complete
            }
        }
    }
}
""")

private let appendNodeMutation = graphql("""
mutation AddTodoAppendNodeMutation($input: AddTodoInput!, $connections: [ID!]!) {
    addTodo(input: $input) {
        todoEdge {
            node @appendNode(connections: $connections, edgeTypeName: "TodoEdge") {
                id
                text
                complete
            }
        }
    }
}
""")

private let prependNodeMutation = graphql("""
mutation AddTodoPrependNodeMutation($input: AddTodoInput!, $connections: [ID!]!) {
    addTodo(input: $input) {
        todoEdge {
            node @prependNode(connections: $connections, edgeTypeName: "TodoEdge") {
                id
                text
                complete
            }
        }
    }
}
""")

public enum AddTodo {
    public static let addBuyGME = """
{
  "data": {
    "addTodo": {
      "todoEdge": {
        "cursor": "notimportant",
        "node": {
          "id": "VG9kbzox2",
          "text": "Buy GME",
          "complete": false
        }
      }
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
