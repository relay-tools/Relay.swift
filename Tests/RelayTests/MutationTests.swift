import XCTest
import Combine
import SnapshotTesting
import Nimble
@testable import Relay
@testable import RelayTestHelpers

class MutationTests: XCTestCase {
    var environment: MockEnvironment!

    override func setUpWithError() throws {
        environment = MockEnvironment()
    }

    func testBasicNodeUpdate() throws {
        try environment.cachePayload(CurrentUserToDoListQuery(), CurrentUserToDoList.myTodos)
        assertSnapshot(matching: environment.store.source, as: .recordSource)

        let input = ChangeTodoStatusInput(
            complete: true, id: "VG9kbzox", userId: "me")
        let op = ChangeTodoStatusMutation(variables: .init(input: input))
        try environment.mockResponse(op, ChangeTodoStatus.completeBuyHorse)

        waitUntilComplete(environment.commitMutation(op))

        assertSnapshot(matching: environment.store.source, as: .recordSource)
    }

    func testBasicNodeUpdateOptimistic() throws {
        try environment.cachePayload(CurrentUserToDoListQuery(), CurrentUserToDoList.myTodos)
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

        let advance = try environment.delayMockedResponse(op, ChangeTodoStatus.error)

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
        try environment.cachePayload(CurrentUserToDoListQuery(), CurrentUserToDoList.myTodos)
        assertSnapshot(matching: environment.store.source, as: .recordSource)

        let input = ChangeTodoStatusInput(
            complete: true, id: "VG9kbzox", userId: "me")
        let op = ChangeTodoStatusMutation(variables: .init(input: input))
        try environment.mockResponse(op, ChangeTodoStatus.completeBuyHorse)

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
        try environment.cachePayload(CurrentUserToDoListQuery(), CurrentUserToDoList.myTodos)
        assertSnapshot(matching: environment.store.source, as: .recordSource)

        let input = ChangeTodoStatusInput(
            complete: true, id: "VG9kbzox", userId: "me")
        let op = ChangeTodoStatusMutation(variables: .init(input: input))
        let advance = try environment.delayMockedResponse(op, ChangeTodoStatus.error)

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
}
