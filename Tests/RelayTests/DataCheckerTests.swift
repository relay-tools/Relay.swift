import XCTest
import Combine
import SnapshotTesting
import Nimble
@testable import Relay
@testable import RelayTestHelpers

class DataCheckerTests: XCTestCase {
    var environment: MockEnvironment!
    var cancellables: Set<AnyCancellable>!

    override func setUpWithError() throws {
        environment = MockEnvironment()
        cancellables = Set<AnyCancellable>()
    }

    func testQueryIsMissingWhenItHasntBeenFetched() throws {
        let operation = MoviesTabQuery().createDescriptor()
        expect(self.environment.check(operation: operation)) == .missing
    }

    func testQueryIsAvailableWhenItHasBeenFetched() throws {
        let op = MoviesTabQuery()
        let operation = op.createDescriptor()
        environment.retain(operation: operation).store(in: &cancellables)

        try environment.mockResponse(op, MoviesTab.allFilms)
        waitUntilComplete(environment.fetchQuery(op))

        let availability = environment.check(operation: operation)
        guard case .available(let date) = availability else {
            fail("Expected query to be available, but it was actually \(availability)")
            return
        }

        expect(date).notTo(beNil())
    }

    func testNoFetchTimeWhenOperationIsNotRetained() throws {
        let op = MoviesTabQuery()
        let operation = op.createDescriptor()

        try environment.mockResponse(op, MoviesTab.allFilms)
        waitUntilComplete(environment.fetchQuery(op))

        expect(self.environment.check(operation: operation)) == .available(nil)
    }

    func testMissingOnceOperationIsGarbageCollected() throws {
        let op = MoviesTabQuery()
        let operation = op.createDescriptor()
        let retainToken: AnyCancellable? = environment.retain(operation: operation)

        try environment.mockResponse(op, MoviesTab.allFilms)
        waitUntilComplete(environment.fetchQuery(op))

        retainToken?.cancel()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.2))

        expect(self.environment.check(operation: operation)) == .missing
    }

    func testStaleWhenEntireStoreIsInvalidated() throws {
        let op = CurrentUserToDoListQuery()
        let operation = op.createDescriptor()
        environment.retain(operation: operation).store(in: &cancellables)

        try environment.mockResponse(op, CurrentUserToDoList.myTodos)
        waitUntilComplete(environment.fetchQuery(op))

        let input = ChangeTodoStatusInput(
            complete: true, id: "VG9kbzox", userId: "me")
        let mutation = ChangeTodoStatusMutation(variables: .init(input: input))
        try environment.mockResponse(mutation, ChangeTodoStatus.completeBuyHorse)
        waitUntilComplete(environment.commitMutation(mutation, updater: { (store, _) in
            store.invalidateStore()
        }))

        expect(self.environment.check(operation: operation)) == .stale
    }

    func testStaleWhenRecordInQueryDataIsInvalidated() throws {
        let op = CurrentUserToDoListQuery()
        let operation = op.createDescriptor()
        environment.retain(operation: operation).store(in: &cancellables)

        try environment.mockResponse(op, CurrentUserToDoList.myTodos)
        waitUntilComplete(environment.fetchQuery(op))

        let input = ChangeTodoStatusInput(
            complete: true, id: "VG9kbzox", userId: "me")
        let mutation = ChangeTodoStatusMutation(variables: .init(input: input))
        try environment.mockResponse(mutation, ChangeTodoStatus.completeBuyHorse)
        waitUntilComplete(environment.commitMutation(mutation, updater: { (store, _) in
            store["VG9kbzox"]!.invalidateRecord()
        }))

        expect(self.environment.check(operation: operation)) == .stale
    }

    func testNotStaleWhenRecordOutsideQueryDataIsInvalidated() throws {
        let op = CurrentUserToDoListQuery()
        let operation = op.createDescriptor()
        environment.retain(operation: operation).store(in: &cancellables)

        try environment.mockResponse(op, CurrentUserToDoList.myTodos)
        waitUntilComplete(environment.fetchQuery(op))

        var record = Record(dataID: "foobar", typename: "Todo")
        record["text"] = "Do the thing"
        environment.store.source["foobar"] = record

        let input = ChangeTodoStatusInput(
            complete: true, id: "VG9kbzox", userId: "me")
        let mutation = ChangeTodoStatusMutation(variables: .init(input: input))
        try environment.mockResponse(mutation, ChangeTodoStatus.completeBuyHorse)
        waitUntilComplete(environment.commitMutation(mutation, updater: { (store, _) in
            store["foobar"]!.invalidateRecord()
        }))

        let availability = environment.check(operation: operation)
        guard case .available(let date) = availability else {
            fail("Expected query to be available, but it was actually \(availability)")
            return
        }

        expect(date).notTo(beNil())
    }
}
