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
        assertSnapshot(matching: environment.store.source, as: .recordSource)

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

        waitUntilComplete(environment.commitMutation(op))

        assertSnapshot(matching: environment.store.source, as: .recordSource)
    }

    func testBasicNodeUpdateOptimistic() throws {
        try loadInitialData()
        assertSnapshot(matching: environment.store.source, as: .recordSource)

        let input = ChangeTodoStatusInput(
            complete: true, id: "VG9kbzox", userId: "me")
        let op = ChangeTodoStatusMutation(variables: .init(input: input))
        let optimisticPayload = [
            "changeTodoStatus": [
                "todo": [
                    "id": "VG9kbzox",
                    "complete": true,
                ],
            ],
        ]

        let payload = """
{
  "errors": [{"message": "This is an error that occurred in the mutation."}],
}
"""
        let parsedPayload = try JSONSerialization.jsonObject(with: payload.data(using: .utf8)!, options: []) as! [String: Any]
        let advance = environment.delayMockedResponse(op, parsedPayload)

        let publisher = environment.commitMutation(op, optimisticResponse: optimisticPayload)
        expect(self.environment.store.source["VG9kbzox"]!["complete"] as? Bool).toEventually(beTrue())
        assertSnapshot(matching: environment.store.source, as: .recordSource)

        advance()
        var completion: Subscribers.Completion<Error>?
        waitUntilComplete(publisher.handleEvents(receiveCompletion: { theCompletion in
            completion = theCompletion
        }))

        expect(completion).toNot(beNil())
        guard case .failure(let error) = completion! else {
            fail("mutation completed successfully when it should have failed")
            return
        }
        expect(error).to(beAKindOf(NetworkError.self))

        assertSnapshot(matching: environment.store.source, as: .recordSource)
    }

    func testDeleteFromListInUpdater() throws {
        try loadInitialData()
        assertSnapshot(matching: environment.store.source, as: .recordSource)

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
        }).handleEvents(receiveOutput: { data in
            assertSnapshot(matching: data, as: .dump)
        }))

        assertSnapshot(matching: environment.store.source, as: .recordSource)
    }

    func testDeleteFromListWithOptimisticUpdater() throws {
        try loadInitialData()
        assertSnapshot(matching: environment.store.source, as: .recordSource)

        let input = ChangeTodoStatusInput(
            complete: true, id: "VG9kbzox", userId: "me")
        let op = ChangeTodoStatusMutation(variables: .init(input: input))
        let payload = """
{
  "errors": [{"message": "This is an error that occurred in the mutation."}],
}
"""
        let parsedPayload = try JSONSerialization.jsonObject(with: payload.data(using: .utf8)!, options: []) as! [String: Any]
        let advance = environment.delayMockedResponse(op, parsedPayload)

        var todosID: DataID?
        let updater: SelectorStoreUpdater = { store, data in
            let user = store.root.getLinkedRecord("user", args: ["id": "me"])!
            var todos = user.getLinkedRecord("todos", args: ["first": 100])!
            todosID = todos.dataID
            ConnectionHandler.default.delete(connection: &todos, nodeID: "VG9kbzox")
        }

        let publisher = environment.commitMutation(op, optimisticUpdater: updater, updater: updater)

        expect(todosID).toNotEventually(beNil())
        expect(self.environment.store.source[todosID!]?.getLinkedRecordIDs("edges")!!).toEventually(haveCount(1))
        assertSnapshot(matching: environment.store.source, as: .recordSource)

        advance()
        var completion: Subscribers.Completion<Error>?
        waitUntilComplete(publisher.handleEvents(receiveCompletion: { theCompletion in
            completion = theCompletion
        }))

        expect(completion).toNot(beNil())
        guard case .failure(let error) = completion! else {
            fail("mutation completed successfully when it should have failed")
            return
        }
        expect(error).to(beAKindOf(NetworkError.self))

        assertSnapshot(matching: environment.store.source, as: .recordSource)
    }

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
    struct Data: Decodable {
        var changeTodoStatus: ChangeTodoStatusPayload_changeTodoStatus?

        struct ChangeTodoStatusPayload_changeTodoStatus: Decodable {
            var todo: Todo_todo

            struct Todo_todo: Decodable {
                var id: String
                var complete: Bool
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
    struct Data: Decodable {
        var user: User_user?

        struct User_user: Decodable {
            var id: String
            var fragment_ToDoList_user: FragmentPointer
        }
    }
}

extension CurrentUserToDoListQuery: Relay.Operation {}
