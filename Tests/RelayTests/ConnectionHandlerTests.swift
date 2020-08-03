import XCTest
import SnapshotTesting
import Nimble
@testable import Relay
@testable import RelayTestHelpers

class ConnectionHandlerTests: XCTestCase {
    private var environment: MockEnvironment!
    private var mutator: RecordSourceMutator!
    private var store: RecordSourceProxy!

    override func setUpWithError() throws {
        environment = MockEnvironment()
    }

    func testUpdateInitialPayload() throws {
        try loadInitialPage()
        assertSnapshot(matching: environment.store.source, as: .recordSource)
    }

    private func loadInitialPage() throws {
        let op = MoviesTabQuery()
        try environment.mockResponse(op, MoviesTab.allFilms)

        waitUntilComplete(environment.fetchQuery(op))
    }

    func testUpdateLoadNext() throws {
        try loadInitialPage()

        let op = MoviesListPaginationQuery(variables: .init(cursor: "YXJyYXljb25uZWN0aW9uOjI="))
        let advance = try environment.delayMockedResponse(op, MoviesTab.prequels)
        advance()

        waitUntilComplete(environment.fetchQuery(op))

        assertSnapshot(matching: environment.store.source, as: .recordSource)
    }

    func testCreateEdge() throws {
        try loadInitialPage()
        createStoreProxy()

        // create a new node to create the edge for
        var node = store.create(dataID: "film_TFA", typeName: "Film")
        node["title"] = "The Force Awakens"

        let connection = ConnectionHandler.default.getConnection(store.root, key: "MoviesList_allFilms")!

        let edge = ConnectionHandler.default.createEdge(&store, connection: connection, node: node, type: "FilmsEdge")
        expect(edge.getLinkedRecord("node")).notTo(beNil())
        expect(edge.getLinkedRecord("node")!.dataID) == node.dataID

        assertSnapshot(matching: mutator.sink, as: .recordSource)
    }

    func testInsertAtBeginningOfList() throws {
        try loadInitialPage()
        createStoreProxy()

        var node = store.create(dataID: "film_TFA", typeName: "Film")
        node["title"] = "The Force Awakens"
        var connection = ConnectionHandler.default.getConnection(store.root, key: "MoviesList_allFilms")!
        let edge = ConnectionHandler.default.createEdge(&store, connection: connection, node: node, type: "FilmsEdge")

        ConnectionHandler.default.insert(connection: &connection, edge: edge, before: nil)

        expect(connection.getLinkedRecords("edges")).notTo(beNil())
        expect(connection.getLinkedRecords("edges")!).to(haveCount(4))

        assertSnapshot(matching: mutator.sink, as: .recordSource)
    }

    func testInsertBeforeCursor() throws {
        try loadInitialPage()
        createStoreProxy()

        var node = store.create(dataID: "film_TFA", typeName: "Film")
        node["title"] = "The Force Awakens"
        var connection = ConnectionHandler.default.getConnection(store.root, key: "MoviesList_allFilms")!
        let edge = ConnectionHandler.default.createEdge(&store, connection: connection, node: node, type: "FilmsEdge")

        ConnectionHandler.default.insert(connection: &connection, edge: edge, before: "YXJyYXljb25uZWN0aW9uOjE=") // cursor for Empire Strikes Back

        expect(connection.getLinkedRecords("edges")).notTo(beNil())
        expect(connection.getLinkedRecords("edges")!).to(haveCount(4))

        assertSnapshot(matching: mutator.sink, as: .recordSource)
    }

    func testInsertAtEndOfList() throws {
        try loadInitialPage()
        createStoreProxy()

        var node = store.create(dataID: "film_TFA", typeName: "Film")
        node["title"] = "The Force Awakens"
        var connection = ConnectionHandler.default.getConnection(store.root, key: "MoviesList_allFilms")!
        let edge = ConnectionHandler.default.createEdge(&store, connection: connection, node: node, type: "FilmsEdge")

        ConnectionHandler.default.insert(connection: &connection, edge: edge, after: nil)

        expect(connection.getLinkedRecords("edges")).notTo(beNil())
        expect(connection.getLinkedRecords("edges")!).to(haveCount(4))

        assertSnapshot(matching: mutator.sink, as: .recordSource)
    }

    func testInsertAfterCursor() throws {
        try loadInitialPage()
        createStoreProxy()

        var node = store.create(dataID: "film_TFA", typeName: "Film")
        node["title"] = "The Force Awakens"
        var connection = ConnectionHandler.default.getConnection(store.root, key: "MoviesList_allFilms")!
        let edge = ConnectionHandler.default.createEdge(&store, connection: connection, node: node, type: "FilmsEdge")

        ConnectionHandler.default.insert(connection: &connection, edge: edge, after: "YXJyYXljb25uZWN0aW9uOjE=") // cursor for Empire Strikes Back

        expect(connection.getLinkedRecords("edges")).notTo(beNil())
        expect(connection.getLinkedRecords("edges")!).to(haveCount(4))

        assertSnapshot(matching: mutator.sink, as: .recordSource)
    }

    func testDeleteNode() throws {
        try loadInitialPage()
        createStoreProxy()

        var connection = ConnectionHandler.default.getConnection(store.root, key: "MoviesList_allFilms")!

        ConnectionHandler.default.delete(connection: &connection, nodeID: "ZmlsbXM6Mw==")

        expect(connection.getLinkedRecords("edges")).notTo(beNil())
        expect(connection.getLinkedRecords("edges")!).to(haveCount(2))

        assertSnapshot(matching: mutator.sink, as: .recordSource)
    }

    private func createStoreProxy() {
        mutator = RecordSourceMutator(base: environment.store.recordSource, sink: DefaultRecordSource())
        store = DefaultRecordSourceProxy(mutator: mutator, handlerProvider: DefaultHandlerProvider())
    }
}
