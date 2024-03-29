// Auto-generated by relay-compiler. Do not edit.

import Relay

public struct AddTodoAppendNodeMutation {
    public var variables: Variables

    public init(variables: Variables) {
        self.variables = variables
    }

    public static var node: ConcreteRequest {
        ConcreteRequest(
            fragment: ReaderFragment(
                name: "AddTodoAppendNodeMutation",
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
                name: "AddTodoAppendNodeMutation",
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
                                        handle: "appendNode",
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
                name: "AddTodoAppendNodeMutation",
                operationKind: .mutation,
                text: """
mutation AddTodoAppendNodeMutation(
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

extension AddTodoAppendNodeMutation {
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

extension RelaySwiftUI.Query.WrappedValue where O == AddTodoAppendNodeMutation {
    public func get(input: AddTodoInput, connections: [String], fetchKey: Any? = nil) -> RelaySwiftUI.Query<AddTodoAppendNodeMutation>.Result {
        self.get(.init(input: input, connections: connections), fetchKey: fetchKey)
    }
}
#endif

#if canImport(RelaySwiftUI)
import RelaySwiftUI

extension RelaySwiftUI.RefetchableFragment.Wrapper where F.Operation == AddTodoAppendNodeMutation {
    public func refetch(input: AddTodoInput, connections: [String]) async {
        await self.refetch(.init(input: input, connections: connections))
    }
}
#endif

extension AddTodoAppendNodeMutation {
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

extension AddTodoAppendNodeMutation: Relay.Operation {}