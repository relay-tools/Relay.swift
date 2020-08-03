import Relay

private let query = graphql("""
query CurrentUserToDoListQuery {
    user(id: "me") {
        id
        ...ToDoList_user
    }
}
""")

public enum CurrentUserToDoList {
    public static let myTodos = """
{
  "data": {
    "user": {
      "id": "VXNlcjptZQ==",
      "todos": {
        "edges": [
          {
            "node": {
              "__typename": "Todo",
              "id": "VG9kbzow",
              "complete": true,
              "text": "Taste JavaScript"
            },
            "cursor": "YXJyYXljb25uZWN0aW9uOjA="
          },
          {
            "node": {
              "__typename": "Todo",
              "id": "VG9kbzox",
              "complete": false,
              "text": "Buy a unicorn"
            },
            "cursor": "YXJyYXljb25uZWN0aW9uOjE="
          }
        ],
        "pageInfo": {
          "endCursor": "YXJyYXljb25uZWN0aW9uOjE=",
          "hasNextPage": false
        }
      }
    }
  }
}
"""

    public static let differentUser = """
{
  "data": {
    "user": {
      "id": "a_new_user_id",
      "todos": {
        "edges": [
          {
            "node": {
              "id": "VG9kbzow",
              "text": "Taste JavaScript",
              "complete": true
            }
          },
          {
            "node": {
              "id": "VG9kbzox",
              "text": "Buy a unicorn",
              "complete": false
            }
          }
        ]
      }
    }
  }
}
"""

    public static let otherTodos = """
{
  "data": {
    "user": {
      "id": "VXNlcjptZQ==",
      "todos": {
        "edges": [
          {
            "node": {
              "id": "VG9kbzow",
              "text": "Taste Swift",
              "complete": true
            }
          },
          {
            "node": {
              "id": "VG9kbzox",
              "text": "Buy a horse",
              "complete": false
            }
          }
        ]
      }
    }
  }
}
"""
}
