import XCTest
import SnapshotTesting
import Nimble
@testable import Relay
@testable import RelayTestHelpers

class MutationHandlersTests: XCTestCase {
    private var environment: MockEnvironment!

    override func setUpWithError() throws {
        environment = MockEnvironment()
    }

    func testAppendEdge() throws {
        try environment.cachePayload(CurrentUserToDoListQuery(), CurrentUserToDoList.myTodos)
        assertSnapshot(matching: environment.store.source, as: .recordSource)

        let connectionID = getConnectionID()

        let input = AddTodoInput(text: "Buy GME", userId: "me")
        let op = AddTodoAppendEdgeMutation(input: input, connections: [connectionID])
        let advance = try environment.delayMockedResponse(op, AddTodo.addBuyGME)
        advance()

        waitUntilComplete(environment.commitMutation(op))

        assertSnapshot(matching: environment.store.source, as: .recordSource)
    }

    func testPrependEdge() throws {
        try environment.cachePayload(CurrentUserToDoListQuery(), CurrentUserToDoList.myTodos)
        assertSnapshot(matching: environment.store.source, as: .recordSource)

        let connectionID = getConnectionID()

        let input = AddTodoInput(text: "Buy GME", userId: "me")
        let op = AddTodoPrependEdgeMutation(input: input, connections: [connectionID])
        let advance = try environment.delayMockedResponse(op, AddTodo.addBuyGME)
        advance()

        waitUntilComplete(environment.commitMutation(op))

        assertSnapshot(matching: environment.store.source, as: .recordSource)
    }

    func testAppendNode() throws {
        try environment.cachePayload(CurrentUserToDoListQuery(), CurrentUserToDoList.myTodos)
        assertSnapshot(matching: environment.store.source, as: .recordSource)

        let connectionID = getConnectionID()

        let input = AddTodoInput(text: "Buy GME", userId: "me")
        let op = AddTodoAppendNodeMutation(input: input, connections: [connectionID])
        let advance = try environment.delayMockedResponse(op, AddTodo.addBuyGME)
        advance()

        waitUntilComplete(environment.commitMutation(op))

        assertSnapshot(matching: environment.store.source, as: .recordSource)
    }

    func testPrependNode() throws {
        try environment.cachePayload(CurrentUserToDoListQuery(), CurrentUserToDoList.myTodos)
        assertSnapshot(matching: environment.store.source, as: .recordSource)

        let connectionID = getConnectionID()

        let input = AddTodoInput(text: "Buy GME", userId: "me")
        let op = AddTodoPrependNodeMutation(input: input, connections: [connectionID])
        let advance = try environment.delayMockedResponse(op, AddTodo.addBuyGME)
        advance()

        waitUntilComplete(environment.commitMutation(op))

        assertSnapshot(matching: environment.store.source, as: .recordSource)
    }

    func testDeleteRecord() throws {
        try environment.cachePayload(CurrentUserToDoListQuery(), CurrentUserToDoList.myTodos)
        assertSnapshot(matching: environment.store.source, as: .recordSource)

        let input = RemoveTodoInput(id: "VG9kbzox", userId: "me")
        let op = RemoveTodoMutation(input: input)
        let advance = try environment.delayMockedResponse(op, RemoveTodo.removeBuyHorse)
        advance()

        waitUntilComplete(environment.commitMutation(op))

        assertSnapshot(matching: environment.store.source, as: .recordSource)
    }

    func testDeleteEdge() throws {
        try environment.cachePayload(CurrentUserToDoListQuery(), CurrentUserToDoList.myTodos)
        assertSnapshot(matching: environment.store.source, as: .recordSource)

        let connectionID = getConnectionID()

        let input = RemoveTodoInput(id: "VG9kbzox", userId: "me")
        let op = RemoveTodoEdgeMutation(input: input, connections: [connectionID])
        let advance = try environment.delayMockedResponse(op, RemoveTodo.removeBuyHorse)
        advance()

        waitUntilComplete(environment.commitMutation(op))

        assertSnapshot(matching: environment.store.source, as: .recordSource)
    }

    private func getConnectionID() -> String {
        let operation = CurrentUserToDoListQuery().createDescriptor()
        let snapshot: Snapshot<CurrentUserToDoListQuery.Data?> = environment.lookup(selector: operation.fragment)

        expect(snapshot.isMissingData).to(beFalse())
        expect(snapshot.data).notTo(beNil())

        let snapshot2: Snapshot<ToDoList_user.Data?> = environment.lookup(selector: ToDoList_user(key: snapshot.data!.user!).selector)
        expect(snapshot2.isMissingData).to(beFalse())
        expect(snapshot2.data).notTo(beNil())

        return snapshot2.data!.todos!.__id
    }
}
