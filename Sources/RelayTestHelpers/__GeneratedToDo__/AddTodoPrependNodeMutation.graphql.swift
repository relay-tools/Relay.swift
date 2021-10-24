// Auto-generated by relay-compiler. Do not edit.

import Relay

public struct AddTodoPrependNodeMutation {
    public var variables: Variables

    public init(variables: Variables) {
        self.variables = variables
    }

    public static var node: ConcreteRequest {
        ConcreteRequest(
            fragment: ReaderFragment(
                name: "AddTodoPrependNodeMutation",
                type: "Mutation",
                selections: [
                    .field(ReaderLinkedField(
                        name: "addTodo",
                        args: [
                            VariableArgument(name: "input", variableName: "input")
                        ],
                        concreteType: "AddTodoPayload",
                        plural: false,
                        selections: [
                            .field(ReaderLinkedField(
                                name: "todoEdge",
                                concreteType: "TodoEdge",
                                plural: false,
                                selections: [
                                    .field(ReaderLinkedField(
                                        name: "node",
                                        concreteType: "Todo",
                                        plural: false,
                                        selections: [
                                            .field(ReaderScalarField(
                                                name: "id"
                                            )),
                                            .field(ReaderScalarField(
                                                name: "text"
                                            )),
                                            .field(ReaderScalarField(
                                                name: "complete"
                                            ))
                                        ]
                                    ))
                                ]
                            ))
                        ]
                    ))
                ]
            ),
            operation: NormalizationOperation(
                name: "AddTodoPrependNodeMutation",
                selections: [
                    .field(NormalizationLinkedField(
                        name: "addTodo",
                        args: [
                            VariableArgument(name: "input", variableName: "input")
                        ],
                        concreteType: "AddTodoPayload",
                        plural: false,
                        selections: [
                            .field(NormalizationLinkedField(
                                name: "todoEdge",
                                concreteType: "TodoEdge",
                                plural: false,
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
                                    )),
                                    .handle(NormalizationHandle(
                                        kind: .linked,
                                        name: "node",
                                        handle: "prependNode",
                                        key: "",
                                        handleArgs: [
                                            VariableArgument(name: "connections", variableName: "connections"),
                                            LiteralArgument(name: "edgeTypeName", value: "TodoEdge")
                                        ]
                                    ))
                                ]
                            ))
                        ]
                    ))
                ]
            ),
            params: RequestParameters(
                name: "AddTodoPrependNodeMutation",
                operationKind: .mutation,
                text: """
mutation AddTodoPrependNodeMutation(
  $input: AddTodoInput!
) {
  addTodo(input: $input) {
    todoEdge {
      node {
        id
        text
        complete
      }
    }
  }
}
"""
            )
        )
    }
}

extension AddTodoPrependNodeMutation {
    public struct Variables: VariableDataConvertible {
        public var input: AddTodoInput
        public var connections: [String]

        public init(input: AddTodoInput, connections: [String]) {
            self.input = input
            self.connections = connections
        }

        public var variableData: VariableData {
            [
                "input": input,
                "connections": connections
            ]
        }
    }

    public init(input: AddTodoInput, connections: [String]) {
        self.init(variables: .init(input: input, connections: connections))
    }
}

#if canImport(RelaySwiftUI)
import RelaySwiftUI

extension RelaySwiftUI.Query.WrappedValue where O == AddTodoPrependNodeMutation {
    public func get(input: AddTodoInput, connections: [String], fetchKey: Any? = nil) -> RelaySwiftUI.Query<AddTodoPrependNodeMutation>.Result {
        self.get(.init(input: input, connections: connections), fetchKey: fetchKey)
    }
}
#endif

#if canImport(RelaySwiftUI)
import RelaySwiftUI

extension RelaySwiftUI.RefetchableFragment.Wrapper where F.Operation == AddTodoPrependNodeMutation {
    public func refetch(input: AddTodoInput, connections: [String]) async {
        await self.refetch(.init(input: input, connections: connections))
    }
}
#endif

public struct AddTodoInput: VariableDataConvertible {
    public var text: String
    public var userId: String
    public var clientMutationId: String?

    public init(text: String, userId: String, clientMutationId: String? = nil) {
        self.text = text
        self.userId = userId
        self.clientMutationId = clientMutationId
    }

    public var variableData: VariableData {
        [
            "text": text,
            "userId": userId,
            "clientMutationId": clientMutationId
        ]
    }
}


extension AddTodoPrependNodeMutation {
    public struct Data: Decodable {
        public var addTodo: AddTodoPayload_addTodo?

        public struct AddTodoPayload_addTodo: Decodable {
            public var todoEdge: TodoEdge_todoEdge?

            public struct TodoEdge_todoEdge: Decodable {
                public var node: Todo_node?

                public struct Todo_node: Decodable, Identifiable {
                    public var id: String
                    public var text: String
                    public var complete: Bool
                }
            }
        }
    }
}

extension AddTodoPrependNodeMutation: Relay.Operation {}