import XCTest
import SnapshotTesting
import Nimble
@testable import Relay
@testable import RelayTestHelpers

class RecordSourceTests: XCTestCase {
    var environment: MockEnvironment!
    
    override func setUpWithError() throws {
        environment = MockEnvironment()
    }

    private var store: Store {
        environment.store
    }
    
    func testRoundtripRecordSource() throws {
        try environment.cachePayload(MoviesTabQuery(), MoviesTab.allFilms)
        
        assertSnapshot(matching: store.recordSource, as: .recordSource)
        
        let data = try JSONEncoder().encode(store.recordSource as! DefaultRecordSource)
        let newSource = try JSONDecoder().decode(DefaultRecordSource.self, from: data)
        
        assertSnapshot(matching: newSource, as: .recordSource)
    }
    
    func testRoundtripRecordSourceWithDeletedIDs() throws {
        try environment.cachePayload(MoviesTabQuery(), MoviesTab.allFilms)
        
        assertSnapshot(matching: store.recordSource, as: .recordSource)
        
        store.recordSource["client:root:__MoviesList_allFilms_connection:edges:0"] = nil
        store.recordSource["ZmlsbXM6MQ=="] = nil
        
        let data = try JSONEncoder().encode(store.recordSource as! DefaultRecordSource)
        let newSource = try JSONDecoder().decode(DefaultRecordSource.self, from: data)
        
        assertSnapshot(matching: newSource, as: .recordSource)
    }
}
