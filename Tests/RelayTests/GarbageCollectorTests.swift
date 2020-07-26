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

        let op = MoviesTabQuery()
        let operation = op.createDescriptor()

        let cancellable = environment.retain(operation: operation)

        try environment.mockResponse(op, allFilmsPayload)
        waitUntilComplete(environment.fetchQuery(op))
        expect(self.environment.store.source.recordIDs).to(haveCount(22))

        cancellable.cancel()

        // it's unclear to me that it's desirable that we delete the root record, but
        // as far as i can tell, that's what JS Relay does
        expect(self.environment.store.source.recordIDs).toEventually(haveCount(0))
    }

    func testDeletesUnreferencedRecordsWhenReleased() throws {
        expect(self.environment.store.source.recordIDs).to(haveCount(1))

        let op = MoviesTabQuery()
        let operation = op.createDescriptor()

        let cancellable = environment.retain(operation: operation)
        try environment.mockResponse(op, allFilmsPayload)
        waitUntilComplete(environment.fetchQuery(op))

        let op2 = MovieDetailQuery(id: "ZmlsbXM6MQ==")
        let operation2 = op2.createDescriptor()

        let cancellable2 = environment.retain(operation: operation2)
        try environment.mockResponse(op2, filmPayload)
        waitUntilComplete(environment.fetchQuery(op2))

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

        let op = MoviesTabQuery()
        let operation = op.createDescriptor()

        let cancellable = environment.retain(operation: operation)
        try environment.mockResponse(op, allFilmsPayload)
        waitUntilComplete(environment.fetchQuery(op))

        let op2 = MovieDetailQuery(id: "ZmlsbXM6MQ==")
        let operation2 = op2.createDescriptor()

        let cancellable2 = environment.retain(operation: operation2)
        try environment.mockResponse(op2, filmPayload)
        waitUntilComplete(environment.fetchQuery(op2))

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

        let op = MoviesTabQuery()
        let operation = op.createDescriptor()

        let cancellable = environment.retain(operation: operation)
        try environment.mockResponse(op, allFilmsPayload)
        waitUntilComplete(environment.fetchQuery(op))

        let op2 = MovieDetailQuery(id: "ZmlsbXM6MQ==")
        let operation2 = op2.createDescriptor()

        let cancellable2 = environment.retain(operation: operation2)
        try environment.mockResponse(op2, filmPayload)
        waitUntilComplete(environment.fetchQuery(op2))

        cancellable2.cancel()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.2))
        expect(self.environment.store.source.recordIDs).to(haveCount(14))

        // Now do it again, to get an actual case where no records are deleted
        let cancellable3 = environment.retain(operation: operation2)
        waitUntilComplete(environment.fetchQuery(op2))
        expect(self.environment.store.source.recordIDs).to(haveCount(14))

        cancellable3.cancel()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.2))
        expect(self.environment.store.source.recordIDs).to(haveCount(14))

        cancellable.cancel()

        // it's unclear to me that it's desirable that we delete the root record, but
        // as far as i can tell, that's what JS Relay does
        expect(self.environment.store.source.recordIDs).toEventually(haveCount(0))
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
