import XCTest
import Combine
import SnapshotTesting
import Nimble
@testable import Relay
@testable import RelayTestHelpers

class LocalDataTests: XCTestCase {
    var environment: MockEnvironment!

    override func setUpWithError() throws {
        environment = MockEnvironment()
    }

    func testSetRootFieldLinkedRecord() throws {
        environment.commitUpdate { store in
            let record = store.create(dataID: .generateClientID(), typeName: "Trip")
            store.root.setLinkedRecord("currentTrip", record: record)
        }

        assertSnapshot(matching: environment.store.source, as: .recordSource)
    }

    func testClearRootFieldLinkedRecord() throws {
        environment.commitUpdate { store in
            let record = store.create(dataID: .generateClientID(), typeName: "Trip")
            store.root.setLinkedRecord("currentTrip", record: record)
        }

        environment.commitUpdate { store in
            store.root["currentTrip"] = NSNull()
        }

        assertSnapshot(matching: environment.store.source, as: .recordSource)
    }
}
