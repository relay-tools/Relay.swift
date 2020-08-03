import XCTest
import Nimble
import SnapshotTesting
@testable import Relay
@testable import RelayTestHelpers

class RecordSourceProxyTests: XCTestCase {
    private var environment: MockEnvironment!
    private var mutator: RecordSourceMutator!
    private var store: RecordSourceProxy!

    override func setUpWithError() throws {
        environment = MockEnvironment()
        try environment.cachePayload(MoviesTabQuery(), MoviesTab.allFilms)
        mutator = RecordSourceMutator(base: environment.store.recordSource, sink: DefaultRecordSource())
        store = DefaultRecordSourceProxy(mutator: mutator, handlerProvider: DefaultHandlerProvider())
    }

    func testRoot() throws {
        let root = store.root
        expect(root.dataID) == "client:root"
    }

    func testReadRecordByID() throws {
        let record = store["ZmlsbXM6Mg=="]
        expect(record).notTo(beNil())
        expect(record!["episodeID"] as? Int) == 5
        expect(record!["title"] as? String) == "The Empire Strikes Back"
    }

    func testTraverseLinkedRecords() throws {
        let connection = ConnectionHandler.default.getConnection(store.root, key: "MoviesList_allFilms")
        expect(connection).notTo(beNil())
        expect(connection!.typeName) == "FilmsConnection"

        let edges = connection!.getLinkedRecords("edges")
        expect(edges).notTo(beNil())
        expect(edges!.count) == 3

        let firstEdge = edges![0]
        expect(firstEdge).notTo(beNil())
        expect(firstEdge!.typeName) == "FilmsEdge"

        let node = firstEdge!.getLinkedRecord("node")
        expect(node).notTo(beNil())
        expect(node!.typeName) == "Film"
        expect(node!["title"] as? String) == "A New Hope"
    }

    func testUpdateRecordField() throws {
        var record = store["ZmlsbXM6Mg=="]
        expect(record).notTo(beNil())
        record!["director"] = "Some Other Guy"
        expect(record!["director"] as? String) == "Some Other Guy"
        assertSnapshot(matching: mutator.sink, as: .recordSource)
    }

    func testDeleteRecord() throws {
        store.delete(dataID: "ZmlsbXM6Mg==")
        expect(self.store["ZmlsbXM6Mg=="]).to(beNil())
        assertSnapshot(matching: mutator.sink, as: .recordSource)
    }

    func testCreateRecord() throws {
        var record = store.create(dataID: "record_123", typeName: "Film")
        record["title"] = "The Force Awakens"
        record["episodeID"] = 7
        assertSnapshot(matching: mutator.sink, as: .recordSource)
    }

    func testGetOrCreateLinkedRecord() throws {
        var record = store.create(dataID: "char_Leia", typeName: "Person")
        record["name"] = "Leia Organa"
        var planet = record.getOrCreateLinkedRecord("homeworld", typeName: "Planet")
        planet["name"] = "Alderaan"
        assertSnapshot(matching: mutator.sink, as: .recordSource)

        let planet2 = record.getOrCreateLinkedRecord("homeworld", typeName: "Planet")
        expect(planet2["name"] as? String) == "Alderaan"
    }
}
