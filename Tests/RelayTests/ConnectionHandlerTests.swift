import XCTest
import SnapshotTesting
@testable import Relay

class ConnectionHandlerTests: XCTestCase {
    private var environment: MockEnvironment!

    override func setUpWithError() throws {
        environment = MockEnvironment()
    }

    func testUpdateInitialPayload() throws {
        try loadInitialPage()
        assertSnapshot(matching: environment.store.recordSource, as: .recordSource)
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

        _ = environment.fetchQuery(op)
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

        _ = environment.fetchQuery(op)

        assertSnapshot(matching: environment.store.recordSource, as: .recordSource)
    }
}
