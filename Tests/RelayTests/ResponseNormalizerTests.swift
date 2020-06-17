import XCTest
import SnapshotTesting
@testable import Relay


class ResponseNormalizerTests: XCTestCase {
    func testNormalizeValidPayload() throws {
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
        let parsedResponse = try GraphQLResponse(dictionary: parsedPayload)

        var recordSource: RecordSource = DefaultRecordSource()
        recordSource[.rootID] = .root

        let op = MoviesTabQuery().createDescriptor()
        let response = ResponseNormalizer.normalize(
            recordSource: recordSource,
            selector: op.root,
            data: parsedResponse.data!,
            request: op.request)
        recordSource = response.source

        assertSnapshot(matching: recordSource, as: .recordSource)
    }
}
