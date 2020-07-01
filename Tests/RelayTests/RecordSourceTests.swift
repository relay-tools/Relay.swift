import XCTest
import SnapshotTesting
import Nimble
@testable import Relay

class RecordSourceTests: XCTestCase {
    var environment: MockEnvironment!
    
    override func setUpWithError() throws {
        environment = MockEnvironment()
    }

    private var store: Store {
        environment.store
    }
    
    func testRoundtripRecordSource() throws {
        try loadInitialData()
        
        assertSnapshot(matching: store.recordSource, as: .recordSource)
        
        let data = try JSONEncoder().encode(store.recordSource as! DefaultRecordSource)
        let newSource = try JSONDecoder().decode(DefaultRecordSource.self, from: data)
        
        assertSnapshot(matching: newSource, as: .recordSource)
    }
    
    func testRoundtripRecordSourceWithDeletedIDs() throws {
        try loadInitialData()
        
        assertSnapshot(matching: store.recordSource, as: .recordSource)
        
        store.recordSource["client:root:__MoviesList_allFilms_connection:edges:0"] = nil
        store.recordSource["ZmlsbXM6MQ=="] = nil
        
        let data = try JSONEncoder().encode(store.recordSource as! DefaultRecordSource)
        let newSource = try JSONDecoder().decode(DefaultRecordSource.self, from: data)
        
        assertSnapshot(matching: newSource, as: .recordSource)
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
