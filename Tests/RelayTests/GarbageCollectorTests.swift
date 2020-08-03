import XCTest
import Combine
import SnapshotTesting
import Nimble
@testable import Relay
@testable import RelayTestHelpers

class GarbageCollectorTests: XCTestCase {
    var environment: MockEnvironment!
    private let gcQueue = DispatchQueue(label: "my-gc-queue")

    override func setUpWithError() throws {
        environment = MockEnvironment(gcScheduler: gcQueue)
    }

    func testClearsEntireStoreWhenNoOperationsAreRetained() throws {
        expect(self.environment.store.source.recordIDs).to(haveCount(1))

        let cancellable = try fetchAndRetain(MoviesTabQuery(), allFilmsPayload)
        expect(self.environment.store.source.recordIDs).to(haveCount(22))

        cancellable.cancel()

        // it's unclear to me that it's desirable that we delete the root record, but
        // as far as i can tell, that's what JS Relay does
        expect(self.environment.store.source.recordIDs).toEventually(haveCount(0))
    }

    func testDeletesUnreferencedRecordsWhenReleased() throws {
        expect(self.environment.store.source.recordIDs).to(haveCount(1))

        let cancellable = try fetchAndRetain(MoviesTabQuery(), allFilmsPayload)
        let cancellable2 = try fetchAndRetain(MovieDetailQuery(id: "ZmlsbXM6MQ=="), filmPayload)

        expect(self.environment.store.source.recordIDs).to(haveCount(22))

        cancellable.cancel()
        expect(self.environment.store.source.recordIDs).toEventually(haveCount(2))

        cancellable2.cancel()

        // it's unclear to me that it's desirable that we delete the root record, but
        // as far as i can tell, that's what JS Relay does
        expect(self.environment.store.source.recordIDs).toEventually(haveCount(0))
    }

    func testCleansUpExcessRecordsFromConnectionAfterFirstRelease() throws {
        expect(self.environment.store.source.recordIDs).to(haveCount(1))

        let cancellable = try fetchAndRetain(MoviesTabQuery(), allFilmsPayload)
        let cancellable2 = try fetchAndRetain(MovieDetailQuery(id: "ZmlsbXM6MQ=="), filmPayload)

        expect(self.environment.store.source.recordIDs).to(haveCount(22))

        cancellable2.cancel()
        expect(self.environment.store.source.recordIDs).toEventually(haveCount(14))

        cancellable.cancel()

        // it's unclear to me that it's desirable that we delete the root record, but
        // as far as i can tell, that's what JS Relay does
        expect(self.environment.store.source.recordIDs).toEventually(haveCount(0))
    }

    func testDeletesNoRecordsOnReleaseWhenTheyAreStillReferenced() throws {
        expect(self.environment.store.source.recordIDs).to(haveCount(1))

        let cancellable = try fetchAndRetain(MoviesTabQuery(), allFilmsPayload)
        let cancellable2 = try fetchAndRetain(MovieDetailQuery(id: "ZmlsbXM6MQ=="), filmPayload)

        cancellable2.cancel()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.2))
        expect(self.environment.store.source.recordIDs).to(haveCount(14))

        // Now do it again, to get an actual case where no records are deleted
        let cancellable3 = try fetchAndRetain(MovieDetailQuery(id: "ZmlsbXM6MQ=="), filmPayload)
        expect(self.environment.store.source.recordIDs).to(haveCount(14))

        cancellable3.cancel()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.2))
        expect(self.environment.store.source.recordIDs).to(haveCount(14))

        cancellable.cancel()

        // it's unclear to me that it's desirable that we delete the root record, but
        // as far as i can tell, that's what JS Relay does
        expect(self.environment.store.source.recordIDs).toEventually(haveCount(0))
    }

    func testOnlyCollectOnFinalRelease() throws {
        expect(self.environment.store.source.recordIDs).to(haveCount(1))

        let cancellable = try fetchAndRetain(MoviesTabQuery(), allFilmsPayload)
        let cancellable2 = try fetchAndRetain(MoviesTabQuery(), allFilmsPayload)

        expect(self.environment.store.source.recordIDs).to(haveCount(38))

        cancellable2.cancel()
        expect(self.environment.store.source.recordIDs).toEventually(haveCount(38))

        cancellable.cancel()

        // it's unclear to me that it's desirable that we delete the root record, but
        // as far as i can tell, that's what JS Relay does
        expect(self.environment.store.source.recordIDs).toEventually(haveCount(0))
    }

    func testPauseCollection() throws {
        expect(self.environment.store.source.recordIDs).to(haveCount(1))

        let cancellable = try fetchAndRetain(MoviesTabQuery(), allFilmsPayload)
        let cancellable2 = try fetchAndRetain(MovieDetailQuery(id: "ZmlsbXM6MQ=="), filmPayload)

        expect(self.environment.store.source.recordIDs).to(haveCount(22))

        let paused = environment.store.pauseGarbageCollection()

        cancellable2.cancel()

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.2))
        expect(self.environment.store.source.recordIDs).to(haveCount(22))

        paused.cancel()

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.2))
        expect(self.environment.store.source.recordIDs).to(haveCount(14))

        cancellable.cancel()
    }

    func testNestedPauseCollection() throws {
        expect(self.environment.store.source.recordIDs).to(haveCount(1))

        let cancellable = try fetchAndRetain(MoviesTabQuery(), allFilmsPayload)
        let cancellable2 = try fetchAndRetain(MovieDetailQuery(id: "ZmlsbXM6MQ=="), filmPayload)

        expect(self.environment.store.source.recordIDs).to(haveCount(22))

        let paused = environment.store.pauseGarbageCollection()

        cancellable2.cancel()

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.2))
        expect(self.environment.store.source.recordIDs).to(haveCount(22))

        let paused2 = environment.store.pauseGarbageCollection()

        paused.cancel()

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.2))
        expect(self.environment.store.source.recordIDs).to(haveCount(22))

        paused2.cancel()

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.2))
        expect(self.environment.store.source.recordIDs).to(haveCount(14))

        cancellable.cancel()
    }

    func testMarksRecordsThroughInlineFragments() throws {
        expect(self.environment.store.source.recordIDs).to(haveCount(1))

        let cancellable = try fetchAndRetain(MoviesTabQuery(), allFilmsPayload)
        let cancellable2 = try fetchAndRetain(MovieDetailNodeQuery(id: "ZmlsbXM6MQ=="), filmNodePayload)

        expect(self.environment.store.source.recordIDs).to(haveCount(33))

        cancellable.cancel()
        expect(self.environment.store.source.recordIDs).toEventually(haveCount(9))

        cancellable2.cancel()

        // it's unclear to me that it's desirable that we delete the root record, but
        // as far as i can tell, that's what JS Relay does
        expect(self.environment.store.source.recordIDs).toEventually(haveCount(0))
    }

    private func fetchAndRetain<Op: Relay.Operation>(_ op: Op, _ payload: String) throws -> AnyCancellable {
        let operation = op.createDescriptor()
        let cancellable = environment.retain(operation: operation)
        try environment.mockResponse(op, payload)
        waitUntilComplete(environment.fetchQuery(op))
        return cancellable
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

private let filmPayload = """
{
  "data": {
    "film": {
      "id": "ZmlsbXM6MQ==",
      "episodeID": 4,
      "title": "A New Hope",
      "director": "George Lucas",
      "releaseDate": "1977-05-25",
      "__typename": "Film"
    }
  }
}
"""

private let filmNodePayload = """
{
  "data": {
    "node": {
      "__typename": "Film",
      "id": "ZmlsbXM6MQ==",
      "episodeID": 4,
      "title": "A New Hope",
      "director": "George Lucas",
      "releaseDate": "1977-05-25",
      "characterConnection": {
        "edges": [
          {
            "node": {
              "id": "cGVvcGxlOjE=",
              "name": "Luke Skywalker"
            }
          },
          {
            "node": {
              "id": "cGVvcGxlOjI=",
              "name": "C-3PO"
            }
          },
          {
            "node": {
              "id": "cGVvcGxlOjM=",
              "name": "R2-D2"
            }
          }
        ]
      }
    }
  }
}
"""
