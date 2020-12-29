import XCTest
import SnapshotTesting
import Nimble
import RelayTestHelpers
@testable import Relay

class ReaderTests: XCTestCase {
    var environment: MockEnvironment!

    override func setUpWithError() throws {
        environment = MockEnvironment()
    }

    func testReadStarWarsFilms() throws {
        let op = MoviesTabQuery()
        try environment.cachePayload(op, MoviesTab.allFilms)

        let source = environment.store.source
        let selector = op.createDescriptor().fragment

        let snapshot = Reader.read(MoviesTabQuery.Data.self, source: source, selector: selector)

        expect(snapshot.data).notTo(beNil())
        assertSnapshot(matching: snapshot.data, as: .dump)
        expect(snapshot.isMissingData).to(beFalse())
    }

    func testReadStarWarsFilmsList() throws {
        let op = MoviesTabQuery()
        try environment.cachePayload(op, MoviesTab.allFilms)

        let source = environment.store.source
        var selector = op.createDescriptor().fragment

        let snapshot = Reader.read(MoviesTabQuery.Data.self, source: source, selector: selector)
        expect(snapshot.data).notTo(beNil())

        selector = MoviesList_films(key: snapshot.data!).selector
        let snapshot2 = Reader.read(MoviesList_films.Data.self, source: source, selector: selector)
        expect(snapshot2.data).notTo(beNil())

        assertSnapshot(matching: snapshot2.data, as: .dump)
        expect(snapshot2.isMissingData).to(beFalse())
    }

    func testReadStarWarsFilmRow() throws {
        let op = MoviesTabQuery()
        try environment.cachePayload(op, MoviesTab.allFilms)

        let source = environment.store.source
        var selector = op.createDescriptor().fragment

        let snapshot = Reader.read(MoviesTabQuery.Data.self, source: source, selector: selector)
        expect(snapshot.data).notTo(beNil())

        selector = MoviesList_films(key: snapshot.data!).selector
        let snapshot2 = Reader.read(MoviesList_films.Data.self, source: source, selector: selector)
        expect(snapshot2.data).notTo(beNil())

        selector = MoviesListRow_film(key: snapshot2.data!.allFilms![0]!).selector
        let snapshot3 = Reader.read(MoviesListRow_film.Data.self, source: source, selector: selector)
        expect(snapshot3.data).notTo(beNil())

        assertSnapshot(matching: snapshot3.data, as: .dump)
        expect(snapshot3.isMissingData).to(beFalse())
    }

    func testReadStarWarsFilmRowNullScalar() throws {
        let op = MoviesTabQuery()
        try environment.cachePayload(op, MoviesTab.allFilms)

        var source = environment.store.source
        var record = source["ZmlsbXM6MQ=="]!
        record["title"] = NSNull()
        source[record.dataID] = record

        var selector = op.createDescriptor().fragment

        let snapshot = Reader.read(MoviesTabQuery.Data.self, source: source, selector: selector)
        expect(snapshot.data).notTo(beNil())

        selector = MoviesList_films(key: snapshot.data!).selector
        let snapshot2 = Reader.read(MoviesList_films.Data.self, source: source, selector: selector)
        expect(snapshot2.data).notTo(beNil())

        selector = MoviesListRow_film(key: snapshot2.data!.allFilms![0]!).selector
        let snapshot3 = Reader.read(MoviesListRow_film.Data.self, source: source, selector: selector)
        expect(snapshot3.data).notTo(beNil())

        assertSnapshot(matching: snapshot3.data, as: .dump)
        expect(snapshot3.isMissingData).to(beFalse())
    }

    func testReadStarWarsFilmRowMissingScalar() throws {
        let op = MoviesTabQuery()
        try environment.cachePayload(op, MoviesTab.allFilms)

        var source = environment.store.source
        var record = source["ZmlsbXM6MQ=="]!
        record["title"] = nil
        source[record.dataID] = record

        var selector = op.createDescriptor().fragment

        let snapshot = Reader.read(MoviesTabQuery.Data.self, source: source, selector: selector)
        expect(snapshot.data).notTo(beNil())

        selector = MoviesList_films(key: snapshot.data!).selector
        let snapshot2 = Reader.read(MoviesList_films.Data.self, source: source, selector: selector)
        expect(snapshot2.data).notTo(beNil())

        selector = MoviesListRow_film(key: snapshot2.data!.allFilms![0]!).selector
        let snapshot3 = Reader.read(MoviesListRow_film.Data.self, source: source, selector: selector)
        expect(snapshot3.data).notTo(beNil())

        assertSnapshot(matching: snapshot3.data, as: .dump)
        expect(snapshot3.isMissingData).to(beTrue())
    }

    func testReadStarWarsFilmsListNullField() throws {
        let op = MoviesTabQuery()
        try environment.cachePayload(op, MoviesTab.allFilms)

        let mutator = RecordSourceMutator(base: environment.store.recordSource, sink: DefaultRecordSource())
        let store = DefaultRecordSourceProxy(mutator: mutator, handlerProvider: DefaultHandlerProvider())

        let allFilms = ConnectionHandler.default.getConnection(store.root, key: "MoviesList_allFilms")!
        allFilms.getLinkedRecords("edges")![0]!["node"] = NSNull()

        environment.store.publish(source: mutator.sink)

        let source = environment.store.source
        var selector = op.createDescriptor().fragment

        let snapshot = Reader.read(MoviesTabQuery.Data.self, source: source, selector: selector)
        expect(snapshot.data).notTo(beNil())

        selector = MoviesList_films(key: snapshot.data!).selector
        let snapshot2 = Reader.read(MoviesList_films.Data.self, source: source, selector: selector)
        expect(snapshot2.data).notTo(beNil())

        assertSnapshot(matching: snapshot2.data, as: .dump)
        expect(snapshot2.isMissingData).to(beFalse())
    }

    func testReadStarWarsFilmsListMissingField() throws {
        let op = MoviesTabQuery()
        try environment.cachePayload(op, MoviesTab.allFilms)

        let mutator = RecordSourceMutator(base: environment.store.recordSource, sink: DefaultRecordSource())
        let store = DefaultRecordSourceProxy(mutator: mutator, handlerProvider: DefaultHandlerProvider())

        let allFilms = ConnectionHandler.default.getConnection(store.root, key: "MoviesList_allFilms")!
        let edges = allFilms.getLinkedRecords("edges")!
        let firstEdge = edges[0]!

        environment.store.source[firstEdge.dataID]!["node"] = nil

        let source = environment.store.source
        var selector = op.createDescriptor().fragment

        let snapshot = Reader.read(MoviesTabQuery.Data.self, source: source, selector: selector)
        expect(snapshot.data).notTo(beNil())

        selector = MoviesList_films(key: snapshot.data!).selector
        let snapshot2 = Reader.read(MoviesList_films.Data.self, source: source, selector: selector)
        expect(snapshot2.data).notTo(beNil())

        assertSnapshot(matching: snapshot2.data, as: .dump)
        expect(snapshot2.isMissingData).to(beTrue())
    }

    func testReadStarWarsFilmsListNullPluralField() throws {
        let op = MoviesTabQuery()
        try environment.cachePayload(op, MoviesTab.allFilms)

        let mutator = RecordSourceMutator(base: environment.store.recordSource, sink: DefaultRecordSource())
        let store = DefaultRecordSourceProxy(mutator: mutator, handlerProvider: DefaultHandlerProvider())

        ConnectionHandler.default.getConnection(store.root, key: "MoviesList_allFilms")!["edges"] = NSNull()

        environment.store.publish(source: mutator.sink)

        let source = environment.store.source
        var selector = op.createDescriptor().fragment

        let snapshot = Reader.read(MoviesTabQuery.Data.self, source: source, selector: selector)
        expect(snapshot.data).notTo(beNil())

        selector = MoviesList_films(key: snapshot.data!).selector
        let snapshot2 = Reader.read(MoviesList_films.Data.self, source: source, selector: selector)
        expect(snapshot2.data).notTo(beNil())

        assertSnapshot(matching: snapshot2.data, as: .dump)
        expect(snapshot2.isMissingData).to(beFalse())
    }

    func testReadStarWarsFilmsListMissingPluralField() throws {
        let op = MoviesTabQuery()
        try environment.cachePayload(op, MoviesTab.allFilms)

        let connID = environment.store.source[.rootID]!.getLinkedRecordID("__MoviesList_allFilms_connection")!!
        environment.store.source[connID]!["edges"] = nil

        let source = environment.store.source
        var selector = op.createDescriptor().fragment

        let snapshot = Reader.read(MoviesTabQuery.Data.self, source: source, selector: selector)
        expect(snapshot.data).notTo(beNil())

        selector = MoviesList_films(key: snapshot.data!).selector
        let snapshot2 = Reader.read(MoviesList_films.Data.self, source: source, selector: selector)
        expect(snapshot2.data).notTo(beNil())

        assertSnapshot(matching: snapshot2.data, as: .dump)
        expect(snapshot2.isMissingData).to(beTrue())
    }

    func testReadStarWarsFilmsListNullPluralFieldElement() throws {
        let op = MoviesTabQuery()
        try environment.cachePayload(op, MoviesTab.allFilms)

        let mutator = RecordSourceMutator(base: environment.store.recordSource, sink: DefaultRecordSource())
        let store = DefaultRecordSourceProxy(mutator: mutator, handlerProvider: DefaultHandlerProvider())

        let allFilms = ConnectionHandler.default.getConnection(store.root, key: "MoviesList_allFilms")!
        var edges = allFilms.getLinkedRecords("edges")!
        edges[0] = nil
        allFilms.setLinkedRecords("edges", records: edges)

        environment.store.publish(source: mutator.sink)

        let source = environment.store.source
        var selector = op.createDescriptor().fragment

        let snapshot = Reader.read(MoviesTabQuery.Data.self, source: source, selector: selector)
        expect(snapshot.data).notTo(beNil())

        selector = MoviesList_films(key: snapshot.data!).selector
        let snapshot2 = Reader.read(MoviesList_films.Data.self, source: source, selector: selector)
        expect(snapshot2.data).notTo(beNil())

        assertSnapshot(matching: snapshot2.data, as: .dump)
        expect(snapshot2.isMissingData).to(beFalse())
    }

    func testReadMissingRequiredField() throws {
        let op = MoviesTabQuery()
        try environment.cachePayload(op, MoviesTab.allFilms)

        var source = environment.store.source
        var record = source["ZmlsbXM6MQ=="]!
        record["id"] = nil
        source[record.dataID] = record

        var selector = op.createDescriptor().fragment

        let snapshot = Reader.read(MoviesTabQuery.Data.self, source: source, selector: selector)
        expect(snapshot.data).notTo(beNil())

        selector = MoviesList_films(key: snapshot.data!).selector
        let snapshot2 = Reader.read(MoviesList_films.Data.self, source: source, selector: selector)
        expect(snapshot2.data).to(beNil())
    }

    func testReadStarWarsFilmsListMissingRecord() throws {
        let op = MoviesTabQuery()
        try environment.cachePayload(op, MoviesTab.allFilms)

        environment.store.source.remove("ZmlsbXM6MQ==")

        let source = environment.store.source
        var selector = op.createDescriptor().fragment

        let snapshot = Reader.read(MoviesTabQuery.Data.self, source: source, selector: selector)
        expect(snapshot.data).notTo(beNil())

        selector = MoviesList_films(key: snapshot.data!).selector
        let snapshot2 = Reader.read(MoviesList_films.Data.self, source: source, selector: selector)
        expect(snapshot2.data).notTo(beNil())

        assertSnapshot(matching: snapshot2.data, as: .dump)
        expect(snapshot2.isMissingData).to(beTrue())
    }

    func testReadInlineFragmentExpectedType() throws {
        let op = MovieDetailNodeQuery(id: "ZmlsbXM6MQ==")
        try environment.cachePayload(op, MovieDetailNode.newHope)

        let source = environment.store.source
        let selector = op.createDescriptor().fragment

        let snapshot = Reader.read(MovieDetailNodeQuery.Data.self, source: source, selector: selector)
        expect(snapshot.data).notTo(beNil())

        assertSnapshot(matching: snapshot.data, as: .dump)
    }

    func testReadInlineFragmentOtherType() throws {
        let op = MovieDetailNodeQuery(id: "cGVvcGxlOjE=")
        try environment.cachePayload(op, MovieDetailNode.lukeSkywalker)

        let source = environment.store.source
        let selector = op.createDescriptor().fragment

        let snapshot = Reader.read(MovieDetailNodeQuery.Data.self, source: source, selector: selector)
        expect(snapshot.data).notTo(beNil())

        assertSnapshot(matching: snapshot.data, as: .dump)
    }
}
