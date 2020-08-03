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

public enum ChangeTodoStatus {
    public static let completeBuyHorse = """
{
  "data": {
    "changeTodoStatus": {
      "todo": {
        "id": "VG9kbzox",
        "complete": true
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
