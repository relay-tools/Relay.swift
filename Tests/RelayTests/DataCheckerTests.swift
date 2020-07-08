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

        try environment.mockResponse(op, allFilmsPayload)
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

        try environment.mockResponse(op, allFilmsPayload)
        waitUntilComplete(environment.fetchQuery(op))

        expect(self.environment.check(operation: operation)) == .available(nil)
    }

    func testMissingOnceOperationIsGarbageCollected() throws {
        let op = MoviesTabQuery()
        let operation = op.createDescriptor()
        let retainToken: AnyCancellable? = environment.retain(operation: operation)

        try environment.mockResponse(op, allFilmsPayload)
        waitUntilComplete(environment.fetchQuery(op))

        retainToken?.cancel()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.2))

        expect(self.environment.check(operation: operation)) == .missing
    }

    func testStaleWhenEntireStoreIsInvalidated() throws {
        let op = CurrentUserToDoListQuery()
        let operation = op.createDescriptor()
        environment.retain(operation: operation).store(in: &cancellables)

        try environment.mockResponse(op, myTodosPayload)
        waitUntilComplete(environment.fetchQuery(op))

        let input = ChangeTodoStatusInput(
            complete: true, id: "VG9kbzox", userId: "me")
        let mutation = ChangeTodoStatusMutation(variables: .init(input: input))
        let payload = """
{
  "data": {
    "changeTodoStatus": {
      "todo": {
        "id": "VG9kbzox",
        "complete": true
      }
    }
  }
}
"""
        try environment.mockResponse(mutation, payload)
        waitUntilComplete(environment.commitMutation(mutation) { (store, _) in
            store.invalidateStore()
        })

        expect(self.environment.check(operation: operation)) == .stale
    }

    func testStaleWhenRecordInQueryDataIsInvalidated() throws {
        let op = CurrentUserToDoListQuery()
        let operation = op.createDescriptor()
        environment.retain(operation: operation).store(in: &cancellables)

        try environment.mockResponse(op, myTodosPayload)
        waitUntilComplete(environment.fetchQuery(op))

        let input = ChangeTodoStatusInput(
            complete: true, id: "VG9kbzox", userId: "me")
        let mutation = ChangeTodoStatusMutation(variables: .init(input: input))
        let payload = """
{
  "data": {
    "changeTodoStatus": {
      "todo": {
        "id": "VG9kbzox",
        "complete": true
      }
    }
  }
}
"""
        try environment.mockResponse(mutation, payload)
        waitUntilComplete(environment.commitMutation(mutation) { (store, _) in
            var record = store["VG9kbzox"]!
            record.invalidateRecord()
        })

        expect(self.environment.check(operation: operation)) == .stale
    }

    func testNotStaleWhenRecordOutsideQueryDataIsInvalidated() throws {
        let op = CurrentUserToDoListQuery()
        let operation = op.createDescriptor()
        environment.retain(operation: operation).store(in: &cancellables)

        try environment.mockResponse(op, myTodosPayload)
        waitUntilComplete(environment.fetchQuery(op))

        var record = Record(dataID: "foobar", typename: "Todo")
        record["text"] = "Do the thing"
        environment.store.source["foobar"] = record

        let input = ChangeTodoStatusInput(
            complete: true, id: "VG9kbzox", userId: "me")
        let mutation = ChangeTodoStatusMutation(variables: .init(input: input))
        let payload = """
{
  "data": {
    "changeTodoStatus": {
      "todo": {
        "id": "VG9kbzox",
        "complete": true
      }
    }
  }
}
"""
        try environment.mockResponse(mutation, payload)
        waitUntilComplete(environment.commitMutation(mutation) { (store, _) in
            var record = store["foobar"]!
            record.invalidateRecord()
        })

        let availability = environment.check(operation: operation)
        guard case .available(let date) = availability else {
            fail("Expected query to be available, but it was actually \(availability)")
            return
        }

        expect(date).notTo(beNil())
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

private let myTodosPayload = """
{
  "data": {
    "user": {
      "id": "VXNlcjptZQ==",
      "todos": {
        "edges": [
          {
            "node": {
              "id": "VG9kbzow",
              "complete": true,
              "text": "Taste JavaScript"
            },
            "cursor": "YXJyYXljb25uZWN0aW9uOjA="
          },
          {
            "node": {
              "id": "VG9kbzox",
              "complete": false,
              "text": "Buy a unicorn"
            },
            "cursor": "YXJyYXljb25uZWN0aW9uOjE="
          }
        ],
        "pageInfo": {
          "endCursor": "YXJyYXljb25uZWN0aW9uOjE=",
          "hasNextPage": false
        }
      }
    }
  }
}
"""
