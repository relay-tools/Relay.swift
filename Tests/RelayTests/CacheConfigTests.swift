import XCTest
import Combine
import SnapshotTesting
import Nimble
import RelayTestHelpers
@testable import Relay

class CacheConfigTests: XCTestCase {
    class FakeNetwork: Network {
        var lastCacheConfig: CacheConfig?

        func execute(request: RequestParameters, variables: VariableData, cacheConfig: CacheConfig) -> AnyPublisher<Data, Error> {
            lastCacheConfig = cacheConfig
            return Result<Data, Error>.success("{\"data\":null}".data(using: .utf8)!)
                .publisher
                .eraseToAnyPublisher()
        }
    }

    var network: FakeNetwork!
    var environment: Environment!

    override func setUpWithError() throws {
        network = FakeNetwork()
        environment = Environment(network: network, store: Store())
    }

    func testPassesEmptyCacheConfigFromFetchQueryIfOmitted() throws {
        waitUntilComplete(environment.fetchQuery(MoviesTabQuery()))
        let cacheConfig = network.lastCacheConfig
        expect(cacheConfig).notTo(beNil())
        expect(cacheConfig?.force).to(beFalse())
        expect(cacheConfig?.poll).to(beNil())
        expect(cacheConfig?.metadata).to(beNil())
        expect(cacheConfig?.transactionID).to(beNil())
    }

    func testPassesCacheConfigThroughFromFetchQuery() throws {
        let givenCacheConfig = CacheConfig(
            force: true,
            poll: 30,
            metadata: ["a": "b"],
            transactionID: "abcd"
        )

        waitUntilComplete(environment.fetchQuery(MoviesTabQuery(), cacheConfig: givenCacheConfig))
        let cacheConfig = network.lastCacheConfig
        expect(cacheConfig).notTo(beNil())
        expect(cacheConfig?.force).to(beTrue())
        expect(cacheConfig?.poll) == 30
        expect(cacheConfig?.metadata as? [String: String]) == ["a": "b"]
        expect(cacheConfig?.transactionID) == "abcd"
    }

    func testPassesEmptyCacheConfigFromCommitMutationIfOmitted() throws {
        waitUntilComplete(environment.commitMutation(ChangeTodoStatusMutation(input: .init(complete: true, id: "foo", userId: "me"))))

        let cacheConfig = network.lastCacheConfig
        expect(cacheConfig).notTo(beNil())
        expect(cacheConfig?.force).to(beTrue())
        expect(cacheConfig?.poll).to(beNil())
        expect(cacheConfig?.metadata).to(beNil())
        expect(cacheConfig?.transactionID).to(beNil())
    }

    func testPassesCacheConfigThroughFromCommitMutation() throws {
        let givenCacheConfig = CacheConfig(
            force: true,
            poll: 30,
            metadata: ["a": "b"],
            transactionID: "abcd"
        )

        waitUntilComplete(environment.commitMutation(ChangeTodoStatusMutation(input: .init(complete: true, id: "foo", userId: "me")), cacheConfig: givenCacheConfig))

        let cacheConfig = network.lastCacheConfig
        expect(cacheConfig).notTo(beNil())
        expect(cacheConfig?.force).to(beTrue())
        expect(cacheConfig?.poll) == 30
        expect(cacheConfig?.metadata as? [String: String]) == ["a": "b"]
        expect(cacheConfig?.transactionID) == "abcd"
    }

    func testRequiresForceForMutations() throws {
        let givenCacheConfig = CacheConfig(
            force: false,
            poll: 30,
            metadata: ["a": "b"],
            transactionID: "abcd"
        )

        waitUntilComplete(environment.commitMutation(ChangeTodoStatusMutation(input: .init(complete: true, id: "foo", userId: "me")), cacheConfig: givenCacheConfig))

        let cacheConfig = network.lastCacheConfig
        expect(cacheConfig).notTo(beNil())
        expect(cacheConfig?.force).to(beTrue())
        expect(cacheConfig?.poll) == 30
        expect(cacheConfig?.metadata as? [String: String]) == ["a": "b"]
        expect(cacheConfig?.transactionID) == "abcd"
    }
}
