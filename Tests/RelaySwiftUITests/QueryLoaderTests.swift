import XCTest
import Combine
import SnapshotTesting
import Nimble
@testable import RelaySwiftUI

class QueryLoaderTests: XCTestCase {
    private var environment: MockEnvironment!
    private var loader: QueryLoader<MoviesTabQuery>!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        environment = MockEnvironment()
        environment.forceFetchFromStore = false
        loader = QueryLoader<MoviesTabQuery>()
        cancellables = Set<AnyCancellable>()
    }
    
    func testIsInitiallyLoading() throws {
        expect(self.loader.isLoading).to(beTrue())
    }
    
    func testFailsWhenNotPassedAnEnvironment() throws {
        expect {
            _ = self.loader.loadIfNeeded(environment: nil, variables: .init())
        }.to(throwAssertion())
    }
    
    func testFailsWhenNotPassedVariables() throws {
        expect {
            _ = self.loader.loadIfNeeded(environment: self.environment)
        }.to(throwAssertion())
    }
    
    func testLoadsInitialDataFromNetwork() throws {
        let advance = environment.delayMockedResponse(MoviesTabQuery(), allFilmsData)
        let result = loader.loadIfNeeded(environment: environment, variables: .init(), fetchPolicy: .networkOnly)
        expect(result).to(beNil())
        
        advance()
        expect { self.loader.result }.toEventuallyNot(beNil())
        let snapshot = try loader.result!.get()
        expect(snapshot.isMissingData).to(beFalse())
        
        assertSnapshot(matching: snapshot.data, as: .dump)
    }
    
    func testSkipsDataInStoreWhenNetworkOnly() throws {
        environment.cachePayload(MoviesTabQuery(), allFilmsData)
        
        let advance = environment.delayMockedResponse(MoviesTabQuery(), allFilmsData)
        let result = loader.loadIfNeeded(environment: environment, variables: .init(), fetchPolicy: .networkOnly)
        expect(result).to(beNil())
        
        advance()
        expect { self.loader.result }.toEventuallyNot(beNil())
        let snapshot = try loader.result!.get()
        expect(snapshot.isMissingData).to(beFalse())
        
        assertSnapshot(matching: snapshot.data, as: .dump)
    }
    
    func testUsesStoreDataWhenStoreAndNetworkPolicy() throws {
        environment.cachePayload(MoviesTabQuery(), allFilmsData)
        
        let advance = environment.delayMockedResponse(MoviesTabQuery(), allFilmsData)
        let result = loader.loadIfNeeded(environment: environment, variables: .init(), fetchPolicy: .storeAndNetwork)
        expect(result).toNot(beNil())
        
        var snapshot = try loader.result!.get()
        expect(snapshot.isMissingData).to(beFalse())
        
        assertSnapshot(matching: snapshot.data, as: .dump)
        
        var resultWasSet = false
        loader.$result.sink { _ in resultWasSet = true }.store(in: &cancellables)
        
        advance()
        expect(resultWasSet).toEventually(beTrue())
        snapshot = try loader.result!.get()
        expect(snapshot.isMissingData).to(beFalse())
        
        assertSnapshot(matching: snapshot.data, as: .dump)
    }
}

private let allFilmsData = [
    "data": [
        "allFilms": [
            "edges": [
                [
                    "node": [
                        "id": "ZmlsbXM6MQ==",
                        "episodeID": 4,
                        "title": "A New Hope",
                        "director": "George Lucas",
                        "releaseDate": "1977-05-25",
                        "__typename": "Film"
                    ],
                    "cursor": "YXJyYXljb25uZWN0aW9uOjA="
                ],
                [
                    "node": [
                        "id": "ZmlsbXM6Mg==",
                        "episodeID": 5,
                        "title": "The Empire Strikes Back",
                        "director": "Irvin Kershner",
                        "releaseDate": "1980-05-17",
                        "__typename": "Film"
                    ],
                    "cursor": "YXJyYXljb25uZWN0aW9uOjE="
                ],
                [
                    "node": [
                        "id": "ZmlsbXM6Mw==",
                        "episodeID": 6,
                        "title": "Return of the Jedi",
                        "director": "Richard Marquand",
                        "releaseDate": "1983-05-25",
                        "__typename": "Film"
                    ],
                    "cursor": "YXJyYXljb25uZWN0aW9uOjI="
                ]
            ],
            "pageInfo": [
                "endCursor": "YXJyYXljb25uZWN0aW9uOjI=",
                "hasNextPage": true
            ]
        ]
    ]
]
