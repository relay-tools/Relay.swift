import XCTest
import SnapshotTesting
@testable import Relay
@testable import RelayTestHelpers

class ResponseNormalizerTests: XCTestCase {
    func testNormalizeValidPayload() throws {
        let parsedPayload = try JSONSerialization.jsonObject(with: MoviesTab.allFilms.data(using: .utf8)!, options: []) as! [String: Any]
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
