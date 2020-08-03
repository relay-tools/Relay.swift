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
        let selector = try load(MoviesTab.allFilms)
        let key = getMovieKey(selector)
        loader.load(from: resource, key: key)
        expect(loader.data).notTo(beNil())
        assertSnapshot(matching: loader.data, as: .dump)
    }
    
    func testReloadsOnRelevantStoreChanges() throws {
        let loader = FragmentLoader<MoviesListRow_film>()
        let selector = try load(MoviesTab.allFilms)
        let key = getMovieKey(selector)
        loader.load(from: resource, key: key)
        expect(loader.data).notTo(beNil())
        assertSnapshot(matching: loader.data, as: .dump)
        
        // update the store with changes
        try environment.cachePayload(MoviesTabQuery(), MoviesTab.evenNewerHope)
        
        expect { loader.data!.title }.toEventually(equal("An Even Newer Hope"))
        assertSnapshot(matching: loader.data, as: .dump)
    }
    
    func testDoesNotReloadOnIrrelevantStoreChanges() throws {
        let loader = FragmentLoader<MoviesListRow_film>()
        let selector = try load(MoviesTab.allFilms)
        let key = getMovieKey(selector)
        loader.load(from: resource, key: key)
        expect(loader.data).notTo(beNil())
        assertSnapshot(matching: loader.data, as: .dump)
        
        var snapshots: [Snapshot<MoviesListRow_film.Data?>?] = []
        loader.$snapshot.dropFirst().sink { snapshots.append($0) }.store(in: &cancellables)
        
        // update the store with changes
        try environment.cachePayload(MoviesTabQuery(), MoviesTab.empireStrikesAgain)
        
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.2))
        expect(snapshots).to(beEmpty())
    }
    
    func testReloadsWhenKeyChanges() throws {
        let loader = FragmentLoader<MoviesListRow_film>()
        let selector = try load(MoviesTab.allFilms)
        let key = getMovieKey(selector)
        loader.load(from: resource, key: key)
        expect(loader.data).notTo(beNil())
        assertSnapshot(matching: loader.data, as: .dump)
        
        // now get the key for empire strikes back instead
        let key2 = getMovieKey(selector, index: 1)
        loader.load(from: resource, key: key2)
        
        expect { loader.data!.title }.toEventually(equal("The Empire Strikes Back"))
        assertSnapshot(matching: loader.data, as: .dump)
    }
    
    func testDoesNotReloadWhenLoadingTheSameData() throws {
        let loader = FragmentLoader<MoviesListRow_film>()
        let selector = try load(MoviesTab.allFilms)
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
