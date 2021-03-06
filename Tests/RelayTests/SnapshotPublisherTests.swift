import XCTest
import Combine
import SnapshotTesting
import Nimble
@testable import Relay
@testable import RelayTestHelpers

class SnapshotPublisherTests: XCTestCase {
    var environment: MockEnvironment!
    var cancellables: Set<AnyCancellable>!

    override func setUpWithError() throws {
        environment = MockEnvironment()
        cancellables = Set<AnyCancellable>()
    }

    override func tearDownWithError() throws {
        cancellables.removeAll()
    }

    func testGetUpdatedDataForFragment() throws {
        try loadInitialData()

        let operation = MoviesTabQuery().createDescriptor()
        let querySnapshot: Snapshot<MoviesTabQuery.Data?> = environment.lookup(selector: operation.fragment)
        let listFragmentSnapshot: Snapshot<MoviesList_films.Data?> = environment.lookup(selector: MoviesList_films(key: querySnapshot.data!).selector)
        var snapshot: Snapshot<MoviesListRow_film.Data?> = environment.lookup(selector: MoviesListRow_film(key: listFragmentSnapshot.data!.allFilms!.edges![0]!.node!).selector)
        assertSnapshot(matching: snapshot.data, as: .dump)

        environment.subscribe(snapshot: snapshot)
            .sink { newSnapshot in snapshot = newSnapshot}
            .store(in: &cancellables)

        var updatedRecordSource = DefaultRecordSource()
        var record = environment.store.source["ZmlsbXM6MQ=="]!
        record["title"] = "Star Wars"
        updatedRecordSource["ZmlsbXM6MQ=="] = record

        environment.store.publish(source: updatedRecordSource)
        _ = environment.store.notify()

        expect(snapshot.data?.title).toEventually(equal("Star Wars"))
        assertSnapshot(matching: snapshot.data, as: .dump)
    }

    func testIgnoreIrrelevantUpdates() throws {
        try loadInitialData()

        let operation = MoviesTabQuery().createDescriptor()
        let querySnapshot: Snapshot<MoviesTabQuery.Data?> = environment.lookup(selector: operation.fragment)
        let listFragmentSnapshot: Snapshot<MoviesList_films.Data?> = environment.lookup(selector: MoviesList_films(key: querySnapshot.data!).selector)
        var snapshot: Snapshot<MoviesListRow_film.Data?> = environment.lookup(selector: MoviesListRow_film(key: listFragmentSnapshot.data!.allFilms!.edges![0]!.node!).selector)
        assertSnapshot(matching: snapshot.data, as: .dump)

        var updateCount = 0
        environment.subscribe(snapshot: snapshot)
            .sink { newSnapshot in
                snapshot = newSnapshot
                updateCount += 1
            }
            .store(in: &cancellables)

        var updatedRecordSource = DefaultRecordSource()
        var record = environment.store.source["ZmlsbXM6Mg=="]!
        record["director"] = "Someone Else"
        updatedRecordSource["ZmlsbXM6Mg=="] = record

        environment.store.publish(source: updatedRecordSource)
        _ = environment.store.notify()

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.2))
        expect(updateCount) == 0
    }

    func testUpdatesForOptimisticUpdate() throws {
        let op = CurrentUserToDoListQuery()
        try environment.cachePayload(op, CurrentUserToDoList.myTodos)

        let operation = op.createDescriptor()
        let selector = SingularReaderSelector(dataID: "VG9kbzox", node: ToDoItem_todo.node, owner: operation.request, variables: operation.request.variables)
        var snapshot: Snapshot<ToDoItem_todo.Data?> = environment.lookup(selector: selector)
        assertSnapshot(matching: snapshot.data, as: .dump)

        var updateCount = 0
        environment.subscribe(snapshot: snapshot)
            .sink { newSnapshot in
                snapshot = newSnapshot
                updateCount += 1
            }
            .store(in: &cancellables)

        let mutation = ChangeTodoStatusMutation(input: .init(complete: true, id: "VG9kbzox", userId: "me"))
        _ = try environment.delayMockedResponse(mutation, ChangeTodoStatus.completeBuyHorse)

        let optimisticPayload = [
            "changeTodoStatus": [
                "todo": [
                    "id": "VG9kbzox",
                    "complete": true,
                ],
            ],
        ]
        environment.commitMutation(mutation, optimisticResponse: optimisticPayload)
            .sink(receiveCompletion: {_ in }) { _ in }
            .store(in: &cancellables)

        // since we haven't advanced, this will be using the optimistic response
        expect(updateCount).toEventually(equal(1))
        assertSnapshot(matching: snapshot.data, as: .dump)
    }

    func testRevertsOptimisticUpdate() throws {
        let op = CurrentUserToDoListQuery()
        try environment.cachePayload(op, CurrentUserToDoList.myTodos)

        let operation = op.createDescriptor()
        let selector = SingularReaderSelector(dataID: "VG9kbzox", node: ToDoItem_todo.node, owner: operation.request, variables: operation.request.variables)
        var snapshot: Snapshot<ToDoItem_todo.Data?> = environment.lookup(selector: selector)
        assertSnapshot(matching: snapshot.data, as: .dump)

        var updateCount = 0
        environment.subscribe(snapshot: snapshot)
            .sink { newSnapshot in
                snapshot = newSnapshot
                updateCount += 1
            }
            .store(in: &cancellables)

        let mutation = ChangeTodoStatusMutation(input: .init(complete: true, id: "VG9kbzox", userId: "me"))
        let advance = try environment.delayMockedResponse(mutation, ChangeTodoStatus.error)

        let optimisticPayload = [
            "changeTodoStatus": [
                "todo": [
                    "id": "VG9kbzox",
                    "complete": true,
                ],
            ],
        ]
        environment.commitMutation(mutation, optimisticResponse: optimisticPayload)
            .sink(receiveCompletion: {_ in }) { _ in }
            .store(in: &cancellables)

        // since we haven't advanced, this will be using the optimistic response
        expect(updateCount).toEventually(equal(1))

        // now we advance so the error happens and we revert the response
        advance()
        expect(updateCount).toEventually(equal(2))
        assertSnapshot(matching: snapshot.data, as: .dump)
    }

    private func loadInitialData() throws {
        let op = MoviesTabQuery()
        try environment.mockResponse(op, MoviesTab.allFilms)

        waitUntilComplete(environment.fetchQuery(op))
    }
}
