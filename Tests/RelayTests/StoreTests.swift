import XCTest
import SnapshotTesting
import Nimble
@testable import Relay
@testable import RelayTestHelpers

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
        try environment.cachePayload(MoviesTabQuery(), MoviesTab.allFilms)

        let operation = MoviesTabQuery().createDescriptor()
        let snapshot: Snapshot<MoviesTabQuery.Data?> = environment.lookup(selector: operation.fragment)

        expect(snapshot.isMissingData).to(beFalse())
        assertSnapshot(matching: snapshot.data, as: .dump)
    }

    func testLookupSnapshotFromFragment() throws {
        try environment.cachePayload(MoviesTabQuery(), MoviesTab.allFilms)

        let operation = MoviesTabQuery().createDescriptor()
        let snapshot: Snapshot<MoviesTabQuery.Data?> = environment.lookup(selector: operation.fragment)

        expect(snapshot.isMissingData).to(beFalse())
        expect(snapshot.data).notTo(beNil())

        let snapshot2: Snapshot<MoviesList_films.Data?> = environment.lookup(selector: MoviesList_films(key: snapshot.data!).selector)
        expect(snapshot2.isMissingData).to(beFalse())
        assertSnapshot(matching: snapshot2.data, as: .dump)
    }
}
