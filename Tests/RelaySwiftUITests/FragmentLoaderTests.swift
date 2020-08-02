import XCTest
import Combine
import SnapshotTesting
import Nimble
import Relay
@testable import RelayTestHelpers
@testable import RelaySwiftUI

class FragmentLoaderTests: XCTestCase {
    private var environment: MockEnvironment!
    private var resource: FragmentResource!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        environment = MockEnvironment()
        environment.forceFetchFromStore = false
        resource = FragmentResource(environment: environment)
        cancellables = Set<AnyCancellable>()
    }
    
    func testStartsWithNoData() throws {
        let loader = FragmentLoader<MoviesListRow_film>()
        expect(loader.data).to(beNil())
    }
    
    func testLoadsDataFromTheStore() throws {
        let loader = FragmentLoader<MoviesListRow_film>()
        let selector = try load(allFilmsPayload)
        let key = getMovieKey(selector)
        loader.load(from: resource, key: key)
        expect(loader.data).notTo(beNil())
        assertSnapshot(matching: loader.data, as: .dump)
    }
    
    func testReloadsOnRelevantStoreChanges() throws {
        let loader = FragmentLoader<MoviesListRow_film>()
        let selector = try load(allFilmsPayload)
        let key = getMovieKey(selector)
        loader.load(from: resource, key: key)
        expect(loader.data).notTo(beNil())
        assertSnapshot(matching: loader.data, as: .dump)
        
        // update the store with changes
        try environment.cachePayload(MoviesTabQuery(), allFilmsRelevantUpdatePayload)
        
        expect { loader.data!.title }.toEventually(equal("An Even Newer Hope"))
        assertSnapshot(matching: loader.data, as: .dump)
    }
    
    func testDoesNotReloadOnIrrelevantStoreChanges() throws {
        let loader = FragmentLoader<MoviesListRow_film>()
        let selector = try load(allFilmsPayload)
        let key = getMovieKey(selector)
        loader.load(from: resource, key: key)
        expect(loader.data).notTo(beNil())
        assertSnapshot(matching: loader.data, as: .dump)
        
        var snapshots: [Snapshot<MoviesListRow_film.Data?>?] = []
        loader.$snapshot.dropFirst().sink { snapshots.append($0) }.store(in: &cancellables)
        
        // update the store with changes
        try environment.cachePayload(MoviesTabQuery(), allFilmsIrrelevantUpdatePayload)
        
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.2))
        expect(snapshots).to(beEmpty())
    }
    
    func testReloadsWhenKeyChanges() throws {
        let loader = FragmentLoader<MoviesListRow_film>()
        let selector = try load(allFilmsPayload)
        let key = getMovieKey(selector)
        loader.load(from: resource, key: key)
        expect(loader.data).notTo(beNil())
        assertSnapshot(matching: loader.data, as: .dump)
        
        // now get the key for empire strikes back instead
        let key2 = getMovieKey(selector, index: 1)
        loader.load(from: environment, key: key2)
        
        expect { loader.data!.title }.toEventually(equal("The Empire Strikes Back"))
        assertSnapshot(matching: loader.data, as: .dump)
    }
    
    func testDoesNotReloadWhenLoadingTheSameData() throws {
        let loader = FragmentLoader<MoviesListRow_film>()
        let selector = try load(allFilmsPayload)
        let key = getMovieKey(selector)
        loader.load(from: resource, key: key)
        expect(loader.data).notTo(beNil())
        assertSnapshot(matching: loader.data, as: .dump)
        
        var snapshots: [Snapshot<MoviesListRow_film.Data?>?] = []
        loader.$snapshot.dropFirst().sink { snapshots.append($0) }.store(in: &cancellables)
        
        loader.load(from: resource, key: key)
        
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.2))
        expect(snapshots).to(beEmpty())
    }
    
    private func load(_ payload: String) throws -> SingularReaderSelector {
        let op = MoviesTabQuery()
        try environment.cachePayload(op, payload)
        return op.createDescriptor().fragment
    }
    
    private func getMovieKey(_ querySelector: SingularReaderSelector, index: Int = 0) -> MoviesListRow_film.Key {
        let snapshot: Snapshot<MoviesTabQuery.Data?> = environment.lookup(selector: querySelector)
        let listSelector = MoviesList_films(key: snapshot.data!).selector
        let snapshot2: Snapshot<MoviesList_films.Data?> = environment.lookup(selector: listSelector)
        return snapshot2.data!.allFilms![index]!
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

// this payload includes a change to episode 4, so that should cause the fragment to update
private let allFilmsRelevantUpdatePayload = """
{
  "data": {
    "allFilms": {
      "edges": [
        {
          "node": {
            "id": "ZmlsbXM6MQ==",
            "episodeID": 4,
            "title": "An Even Newer Hope",
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

// this payload includes a change to a different film, so it shouldn't cause any
// updates for this fragment.
private let allFilmsIrrelevantUpdatePayload = """
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
            "title": "The Empire Strikes Again",
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
