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
        try environment.cachePayload(op, allFilmsPayload)

        let source = environment.store.source
        let selector = op.createDescriptor().fragment

        let snapshot = Reader.read(MoviesTabQuery.Data.self, source: source, selector: selector)

        expect(snapshot.data).notTo(beNil())
        assertSnapshot(matching: snapshot.data, as: .dump)
        expect(snapshot.isMissingData).to(beFalse())
    }

    func testReadStarWarsFilmsList() throws {
        let op = MoviesTabQuery()
        try environment.cachePayload(op, allFilmsPayload)

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
        try environment.cachePayload(op, allFilmsPayload)

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
        try environment.cachePayload(op, allFilmsPayload)

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
        try environment.cachePayload(op, allFilmsPayload)

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
}

private let allFilmsPayload = """
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
