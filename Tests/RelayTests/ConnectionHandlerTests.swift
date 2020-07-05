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
        let payload = """
        {
          "data": {
            "allFilms": {
              "edges": [
                {
                  "node": {
                    "id": "ZmlsbXM6MQ==",
                    "episodeID": 4,
                    "title": "A New Hope",
                    "director": "George Lucas",
                    "releaseDate": "1977-05-25",
                    "__typename": "Film"
                  },
                  "cursor": "YXJyYXljb25uZWN0aW9uOjA="
                },
                {
                  "node": {
                    "id": "ZmlsbXM6Mg==",
                    "episodeID": 5,
                    "title": "The Empire Strikes Back",
                    "director": "Irvin Kershner",
                    "releaseDate": "1980-05-17",
                    "__typename": "Film"
                  },
                  "cursor": "YXJyYXljb25uZWN0aW9uOjE="
                },
                {
                  "node": {
                    "id": "ZmlsbXM6Mw==",
                    "episodeID": 6,
                    "title": "Return of the Jedi",
                    "director": "Richard Marquand",
                    "releaseDate": "1983-05-25",
                    "__typename": "Film"
                  },
                  "cursor": "YXJyYXljb25uZWN0aW9uOjI="
                }
              ],
              "pageInfo": {
                "endCursor": "YXJyYXljb25uZWN0aW9uOjI=",
                "hasNextPage": true
              }
            }
          }
        }
        """
        let parsedPayload = try JSONSerialization.jsonObject(with: payload.data(using: .utf8)!, options: []) as! [String: Any]
        let op = MoviesTabQuery()
        environment.mockResponse(op, parsedPayload)

        waitUntilComplete(environment.fetchQuery(op))
    }

    func testUpdateLoadNext() throws {
        try loadInitialPage()

        let payload = """
{
  "data": {
    "allFilms": {
      "edges": [
        {
          "node": {
            "id": "ZmlsbXM6NA==",
            "episodeID": 1,
            "title": "The Phantom Menace",
            "director": "George Lucas",
            "releaseDate": "1999-05-19",
            "__typename": "Film"
          },
          "cursor": "YXJyYXljb25uZWN0aW9uOjM="
        },
        {
          "node": {
            "id": "ZmlsbXM6NQ==",
            "episodeID": 2,
            "title": "Attack of the Clones",
            "director": "George Lucas",
            "releaseDate": "2002-05-16",
            "__typename": "Film"
          },
          "cursor": "YXJyYXljb25uZWN0aW9uOjQ="
        },
        {
          "node": {
            "id": "ZmlsbXM6Ng==",
            "episodeID": 3,
            "title": "Revenge of the Sith",
            "director": "George Lucas",
            "releaseDate": "2005-05-19",
            "__typename": "Film"
          },
          "cursor": "YXJyYXljb25uZWN0aW9uOjU="
        }
      ],
      "pageInfo": {
        "endCursor": "YXJyYXljb25uZWN0aW9uOjU=",
        "hasNextPage": false
      }
    }
  }
}
"""
        let parsedPayload = try JSONSerialization.jsonObject(with: payload.data(using: .utf8)!, options: []) as! [String: Any]
        let op = MoviesListPaginationQuery(variables: .init(cursor: "YXJyYXljb25uZWN0aW9uOjI="))
        environment.mockResponse(op, parsedPayload)

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
