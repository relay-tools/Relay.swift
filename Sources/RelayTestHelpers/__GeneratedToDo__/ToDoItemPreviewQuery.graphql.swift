// Auto-generated by relay-compiler. Do not edit.

import Relay

struct ToDoItemPreviewQuery {
    var variables: Variables

    init(variables: Variables) {
        self.variables = variables
    }

    static var node: ConcreteRequest {
        ConcreteRequest(
            fragment: ReaderFragment(
                name: "ToDoItemPreviewQuery",
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
                            .field(ReaderLinkedField(
                                name: "todos",
                                args: [
                                    LiteralArgument(name: "first", value: 3)
                                ],
                                concreteType: "TodoConnection",
                                plural: false,
                                selections: [
                                    .field(ReaderLinkedField(
                                        name: "edges",
                                        concreteType: "TodoEdge",
                                        plural: true,
                                        selections: [
                                            .field(ReaderLinkedField(
                                                name: "node",
                                                concreteType: "Todo",
                                                plural: false,
                                                selections: [
                                                    .field(ReaderScalarField(
                                                        name: "id"
                                                    )),
                                                    .fragmentSpread(ReaderFragmentSpread(
                                                        name: "ToDoItem_todo"
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
            operation: NormalizationOperation(
                name: "ToDoItemPreviewQuery",
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
                            .field(NormalizationLinkedField(
                                name: "todos",
                                args: [
                                    LiteralArgument(name: "first", value: 3)
                                ],
                                storageKey: "todos(first:3)",
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
                            )),
                            .field(NormalizationScalarField(
                                name: "id"
                            ))
                        ]
                    ))
                ]),
            params: RequestParameters(
                name: "ToDoItemPreviewQuery",
                operationKind: .query,
                text: """
query ToDoItemPreviewQuery {
  user(id: "me") {
    todos(first: 3) {
      edges {
        node {
          id
          ...ToDoItem_todo
        }
      }
    }
    id
  }
}

fragment ToDoItem_todo on Todo {
  id
  text
  complete
}
"""))
    }
}


extension ToDoItemPreviewQuery {
    typealias Variables = EmptyVariables
}

extension ToDoItemPreviewQuery {
    struct Data: Decodable {
        var user: User_user?

        struct User_user: Decodable {
            var todos: TodoConnection_todos?

            struct TodoConnection_todos: Decodable {
                var edges: [TodoEdge_edges?]?

                struct TodoEdge_edges: Decodable {
                    var node: Todo_node?

                    struct Todo_node: Decodable, Identifiable, ToDoItem_todo_Key {
                        var id: String
                        var fragment_ToDoItem_todo: FragmentPointer
                    }
                }
            }
        }
    }
}

extension ToDoItemPreviewQuery: Relay.Operation {}
