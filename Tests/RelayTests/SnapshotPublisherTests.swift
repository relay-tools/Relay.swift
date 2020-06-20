import XCTest
import Combine
import SnapshotTesting
import Nimble
@testable import Relay

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
        let op = MoviesTabQuery()
        environment.mockResponse(op, parsedPayload)

        waitUntilComplete(environment.fetchQuery(op))
    }
}
