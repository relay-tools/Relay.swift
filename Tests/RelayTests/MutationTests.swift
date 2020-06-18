import XCTest
import Combine
import SnapshotTesting
import Nimble
@testable import Relay

class MutationTests: XCTestCase {
    var environment: MockEnvironment!

    override func setUpWithError() throws {
        environment = MockEnvironment()
    }

    func testBasicNodeUpdate() throws {
        try loadInitialData()

        let input = ChangeTodoStatusInput(
            complete: true, id: "VG9kbzox", userId: "me")
        let op = ChangeTodoStatusMutation(variables: .init(input: input))
        let payload = """
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
        let parsedPayload = try JSONSerialization.jsonObject(with: payload.data(using: .utf8)!, options: []) as! [String: Any]
        environment.mockResponse(op, parsedPayload)

        _ = environment.commitMutation(op)

        assertSnapshot(matching: environment.store.recordSource, as: .recordSource)
    }

    func testDeleteFromListInUpdater() throws {
        try loadInitialData()

        let input = ChangeTodoStatusInput(
            complete: true, id: "VG9kbzox", userId: "me")
        let op = ChangeTodoStatusMutation(variables: .init(input: input))
        let payload = """
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
        let parsedPayload = try JSONSerialization.jsonObject(with: payload.data(using: .utf8)!, options: []) as! [String: Any]
        environment.mockResponse(op, parsedPayload)

        waitUntilComplete(environment.commitMutation(op, updater: { store, data in
            let user = store.root.getLinkedRecord("user", args: ["id": "me"])!
            var todos = user.getLinkedRecord("todos", args: ["first": 100])!
            ConnectionHandler.default.delete(connection: &todos, nodeID: "VG9kbzox")
        }))

        assertSnapshot(matching: environment.store.recordSource, as: .recordSource)
    }

    // TODO test optimistic updates once we support delayed response in the mock environment

    private func loadInitialData() throws {
        let payload = """
{
  "data": {
    "user": {
      "id": "VXNlcjptZQ==",
      "todos": {
        "edges": [
          {
            "node": {
              "id": "VG9kbzow",
              "complete": true,
              "text": "Taste JavaScript"
            },
            "cursor": "YXJyYXljb25uZWN0aW9uOjA="
          },
          {
            "node": {
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
        let parsedPayload = try JSONSerialization.jsonObject(with: payload.data(using: .utf8)!, options: []) as! [String: Any]
        environment.cachePayload(CurrentUserToDoListQuery(), parsedPayload)
        assertSnapshot(matching: environment.store.recordSource, as: .recordSource)
    }
}

// Copied from RelayTodo example app

struct ChangeTodoStatusMutation {
    var variables: Variables

    init(variables: Variables) {
        self.variables = variables
    }

    static var node: ConcreteRequest {
        ConcreteRequest(
            fragment: ReaderFragment(
                name: "ChangeTodoStatusMutation",
                type: "Mutation",
                selections: [
                    .field(ReaderLinkedField(
                        name: "changeTodoStatus",
                        args: [
                            VariableArgument(name: "input", variableName: "input")
                        ],
                        concreteType: "ChangeTodoStatusPayload",
                        plural: false,
                        selections: [
                            .field(ReaderLinkedField(
                                name: "todo",
                                concreteType: "Todo",
                                plural: false,
                                selections: [
                                    .field(ReaderScalarField(
                                        name: "id"
                                    )),
                                    .field(ReaderScalarField(
                                        name: "complete"
                                    ))
                                ]
                            ))
                        ]
                    ))
                ]),
            operation: NormalizationOperation(
                name: "ChangeTodoStatusMutation",
                selections: [
                    .field(NormalizationLinkedField(
                        name: "changeTodoStatus",
                        args: [
                            VariableArgument(name: "input", variableName: "input")
                        ],
                        concreteType: "ChangeTodoStatusPayload",
                        plural: false,
                        selections: [
                            .field(NormalizationLinkedField(
                                name: "todo",
                                concreteType: "Todo",
                                plural: false,
                                selections: [
                                    .field(NormalizationScalarField(
                                        name: "id"
                                    )),
                                    .field(NormalizationScalarField(
                                        name: "complete"
                                    ))
                                ]
                            ))
                        ]
                    ))
                ]),
            params: RequestParameters(
                name: "ChangeTodoStatusMutation",
                operationKind: .mutation,
                text: """
mutation ChangeTodoStatusMutation(
  $input: ChangeTodoStatusInput!
) {
  changeTodoStatus(input: $input) {
    todo {
      id
      complete
    }
  }
}
"""))
    }
}


extension ChangeTodoStatusMutation {
    struct Variables: VariableDataConvertible {
        var input: ChangeTodoStatusInput

        var variableData: VariableData {
            [
                "input": input,
            ]
        }
    }
}

struct ChangeTodoStatusInput: VariableDataConvertible {
    var complete: Bool
    var id: String
    var userId: String
    var clientMutationId: String?

    var variableData: VariableData {
        [
            "complete": complete,
            "id": id,
            "userId": userId,
            "clientMutationId": clientMutationId,
        ]
    }
}

extension ChangeTodoStatusMutation {
    struct Data: Readable {
        var changeTodoStatus: ChangeTodoStatusPayload_changeTodoStatus?

        init(from data: SelectorData) {
            changeTodoStatus = data.get(ChangeTodoStatusPayload_changeTodoStatus?.self, "changeTodoStatus")
        }

        struct ChangeTodoStatusPayload_changeTodoStatus: Readable {
            var todo: Todo_todo

            init(from data: SelectorData) {
                todo = data.get(Todo_todo.self, "todo")
            }

            struct Todo_todo: Readable {
                var id: String
                var complete: Bool

                init(from data: SelectorData) {
                    id = data.get(String.self, "id")
                    complete = data.get(Bool.self, "complete")
                }
            }
        }
    }
}

extension ChangeTodoStatusMutation: Relay.Operation {}

struct CurrentUserToDoListQuery {
    var variables: Variables

    init(variables: Variables) {
        self.variables = variables
    }

    static var node: ConcreteRequest {
        ConcreteRequest(
            fragment: ReaderFragment(
                name: "CurrentUserToDoListQuery",
                type: "Query",
                selections: [
                    .field(ReaderLinkedField(
                        name: "user",
                        args: [
                            LiteralArgument(name: "id", value: "me")
                        ],
                        concreteType: "User",
                        plural: false,
                        selections: [
                            .field(ReaderScalarField(
                                name: "id"
                            )),
                            .fragmentSpread(ReaderFragmentSpread(
                                name: "ToDoList_user"
                            ))
                        ]
                    ))
                ]),
            operation: NormalizationOperation(
                name: "CurrentUserToDoListQuery",
                selections: [
                    .field(NormalizationLinkedField(
                        name: "user",
                        args: [
                            LiteralArgument(name: "id", value: "me")
                        ],
                        storageKey: "user(id:\"me\")",
                        concreteType: "User",
                        plural: false,
                        selections: [
                            .field(NormalizationScalarField(
                                name: "id"
                            )),
                            .field(NormalizationLinkedField(
                                name: "todos",
                                args: [
                                    LiteralArgument(name: "first", value: 100)
                                ],
                                storageKey: "todos(first:100)",
                                concreteType: "TodoConnection",
                                plural: false,
                                selections: [
                                    .field(NormalizationLinkedField(
                                        name: "edges",
                                        concreteType: "TodoEdge",
                                        plural: true,
                                        selections: [
                                            .field(NormalizationLinkedField(
                                                name: "node",
                                                concreteType: "Todo",
                                                plural: false,
                                                selections: [
                                                    .field(NormalizationScalarField(
                                                        name: "id"
                                                    )),
                                                    .field(NormalizationScalarField(
                                                        name: "text"
                                                    )),
                                                    .field(NormalizationScalarField(
                                                        name: "complete"
                                                    ))
                                                ]
                                            ))
                                        ]
                                    ))
                                ]
                            ))
                        ]
                    ))
                ]),
            params: RequestParameters(
                name: "CurrentUserToDoListQuery",
                operationKind: .query,
                text: """
query CurrentUserToDoListQuery {
  user(id: "me") {
    id
    ...ToDoList_user
  }
}

fragment ToDoItem_todo on Todo {
  id
  text
  complete
}

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
"""))
    }
}


extension CurrentUserToDoListQuery {
    typealias Variables = EmptyVariables
}

extension CurrentUserToDoListQuery {
    struct Data: Readable {
        var user: User_user?

        init(from data: SelectorData) {
            user = data.get(User_user?.self, "user")
        }

        struct User_user: Readable {
            var id: String
            var fragment_ToDoList_user: FragmentPointer

            init(from data: SelectorData) {
                id = data.get(String.self, "id")
                fragment_ToDoList_user = data.get(fragment: "ToDoList_user")
            }
        }
    }
}

extension CurrentUserToDoListQuery: Relay.Operation {}
