import XCTest
import SnapshotTesting
import Nimble
@testable import Relay

class StoreTests: XCTestCase {
    var environment: MockEnvironment!

    override func setUpWithError() throws {
        environment = MockEnvironment()
    }

    private var store: Store {
        environment.store
    }

    func testInitialState() throws {
        assertSnapshot(matching: store.source, as: .recordSource)
    }

    func testSnapshotCreatesOptimisticSource() throws {
        expect(self.store.optimisticSource).to(beNil())
        store.snapshot()
        expect(self.store.optimisticSource).notTo(beNil())
    }

    func testSnapshotFailsIfAlreadySnapshotted() throws {
        store.snapshot()
        expect { self.store.snapshot() }.to(throwAssertion())
    }

    func testRestoreClearsOptimisticSource() throws {
        store.snapshot()
        expect(self.store.optimisticSource).notTo(beNil())
        store.restore()
        expect(self.store.optimisticSource).to(beNil())
    }

    func testRestoreFailsIfNotSnapshotted() throws {
        expect { self.store.restore() }.to(throwAssertion())
    }

    func testLookupSnapshotFromQuery() throws {
        try loadInitialData()

        let operation = MoviesTabQuery().createDescriptor()
        let snapshot: Snapshot<MoviesTabQuery.Data?> = environment.lookup(selector: operation.fragment)

        expect(snapshot.isMissingData).to(beFalse())
        assertSnapshot(matching: snapshot.data, as: .dump)
    }

    func testLookupSnapshotFromFragment() throws {
        try loadInitialData()

        let operation = MoviesTabQuery().createDescriptor()
        let snapshot: Snapshot<MoviesTabQuery.Data?> = environment.lookup(selector: operation.fragment)

        expect(snapshot.isMissingData).to(beFalse())
        expect(snapshot.data).notTo(beNil())

        let snapshot2: Snapshot<MoviesList_films.Data?> = environment.lookup(selector: MoviesList_films(key: snapshot.data!).selector)
        expect(snapshot2.isMissingData).to(beFalse())
        assertSnapshot(matching: snapshot2.data, as: .dump)
    }

    private func loadInitialData() throws {
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
        environment.cachePayload(MoviesTabQuery(), parsedPayload)
    }
}
