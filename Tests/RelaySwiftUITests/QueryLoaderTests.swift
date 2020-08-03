import XCTest
import Combine
import SnapshotTesting
import Nimble
import Relay
@testable import RelayTestHelpers
@testable import RelaySwiftUI

class QueryLoaderTests: XCTestCase {
    private var environment: MockEnvironment!
    private var resource: QueryResource!
    private var fragmentResource: FragmentResource!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        environment = MockEnvironment()
        environment.forceFetchFromStore = false
        resource = QueryResource(environment: environment)
        fragmentResource = FragmentResource(environment: environment)
        cancellables = Set<AnyCancellable>()
    }
    
    func testIsInitiallyLoading() throws {
        let loader = QueryLoader<MoviesTabQuery>()
        expect(loader.isLoading).to(beTrue())
        expect(loader.data).to(beNil())
        expect(loader.error).to(beNil())
    }
    
    func testFailsWhenNotPassedVariables() throws {
        let loader = QueryLoader<MoviesTabQuery>()
        expect {
            _ = loader.loadIfNeeded(
                resource: self.resource,
                fragmentResource: self.fragmentResource,
                fetchPolicy: .storeOrNetwork
            )
        }.to(throwAssertion())
    }
    
    func testLoadsInitialDataFromNetwork() throws {
        let loader = QueryLoader<MoviesTabQuery>()
        let advance = try environment.delayMockedResponse(MoviesTabQuery(), MoviesTab.allFilms)
        let result = loader.loadIfNeeded(
            resource: resource,
            fragmentResource: fragmentResource,
            variables: .init(),
            fetchPolicy: .networkOnly
        )
        expect(result).to(beNil())
        
        advance()
        expect { loader.result }.toEventuallyNot(beNil())
        let snapshot = try loader.result!.get()
        expect(snapshot.isMissingData).to(beFalse())
        
        assertSnapshot(matching: snapshot.data, as: .dump)
        expect(loader.data).notTo(beNil())
        expect(loader.error).to(beNil())
        expect(loader.isLoading).to(beFalse())
    }
    
    func testSkipsDataInStoreWhenNetworkOnly() throws {
        try environment.cachePayload(MoviesTabQuery(), MoviesTab.allFilms)
        
        let advance = try environment.delayMockedResponse(MoviesTabQuery(), MoviesTab.allFilms)
        let loader = QueryLoader<MoviesTabQuery>()
        let result = loader.loadIfNeeded(
            resource: resource,
            fragmentResource: fragmentResource,
            variables: .init(),
            fetchPolicy: .networkOnly
        )
        expect(result).to(beNil())
        
        advance()
        expect { loader.result }.toEventuallyNot(beNil())
        let snapshot = try loader.result!.get()
        expect(snapshot.isMissingData).to(beFalse())
        
        assertSnapshot(matching: snapshot.data, as: .dump)
    }
    
    func testUsesStoreDataWhenStoreAndNetworkPolicy() throws {
        try environment.cachePayload(MoviesTabQuery(), MoviesTab.allFilms)
        
        let advance = try environment.delayMockedResponse(MoviesTabQuery(), MoviesTab.onlyNewHope)
        let loader = QueryLoader<MoviesTabQuery>()
        let result = loader.loadIfNeeded(
            resource: resource,
            fragmentResource: fragmentResource,
            variables: .init(),
            fetchPolicy: .storeAndNetwork
        )
        expect(result).toNot(beNil())
        
        var snapshot = try loader.result!.get()
        expect(snapshot.isMissingData).to(beFalse())
        
        assertSnapshot(matching: snapshot.data, as: .dump)
        
        var resultWasSet = false
        loader.$result.dropFirst().sink { _ in resultWasSet = true }.store(in: &cancellables)

        advance()
        expect(resultWasSet).toEventually(beTrue())
        snapshot = try loader.result!.get()
        expect(snapshot.isMissingData).to(beFalse())
        
        assertSnapshot(matching: snapshot.data, as: .dump)
    }

    func testDoesNotFetchWhenStoreOnlyPolicy() throws {
        try environment.cachePayload(MoviesTabQuery(), MoviesTab.allFilms)

        let loader = QueryLoader<MoviesTabQuery>()
        let advance = try environment.delayMockedResponse(MoviesTabQuery(), MoviesTab.error)
        let result = loader.loadIfNeeded(
            resource: resource,
            fragmentResource: fragmentResource,
            variables: .init(),
            fetchPolicy: .storeOnly
        )
        expect(result).notTo(beNil())
        expect(loader.data).notTo(beNil())

        var resultWasSet = false
        loader.$result.dropFirst().sink { _ in resultWasSet = true }.store(in: &cancellables)

        advance()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.2))
        expect(resultWasSet).to(beFalse())

        expect(loader.error).to(beNil())
        expect(loader.isLoading).to(beFalse())
        assertSnapshot(matching: loader.data, as: .dump)
    }

    func testFetchesWhenNoDataWhenStoreOrNetworkPolicy() throws {
        let advance = try environment.delayMockedResponse(MoviesTabQuery(), MoviesTab.allFilms)
        let loader = QueryLoader<MoviesTabQuery>()
        let result = loader.loadIfNeeded(
            resource: resource,
            fragmentResource: fragmentResource,
            variables: .init(),
            fetchPolicy: .storeOrNetwork
        )
        expect(result).to(beNil())

        advance()
        expect { loader.result }.toEventuallyNot(beNil())
        let snapshot = try loader.result!.get()
        expect(snapshot.isMissingData).to(beFalse())

        assertSnapshot(matching: snapshot.data, as: .dump)
    }

    func testUsesStoreDataWhenStoreOrNetworkPolicy() throws {
        try environment.cachePayload(MoviesTabQuery(), MoviesTab.allFilms)

        let advance = try environment.delayMockedResponse(MoviesTabQuery(), MoviesTab.onlyNewHope)
        let loader = QueryLoader<MoviesTabQuery>()
        let result = loader.loadIfNeeded(
            resource: resource,
            fragmentResource: fragmentResource,
            variables: .init(),
            fetchPolicy: .storeOrNetwork
        )
        expect(result).toNot(beNil())

        let snapshot = try loader.result!.get()
        expect(snapshot.isMissingData).to(beFalse())

        assertSnapshot(matching: snapshot.data, as: .dump)

        var resultWasSet = false
        loader.$result.dropFirst().sink { _ in resultWasSet = true }.store(in: &cancellables)

        advance()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.2))
        expect(resultWasSet).to(beFalse())

        assertSnapshot(matching: loader.data, as: .dump)
    }
    
    func testDoesNotReloadIfNothingChanged() throws {
        let advance = try environment.delayMockedResponse(MoviesTabQuery(), MoviesTab.allFilms)
        let loader = QueryLoader<MoviesTabQuery>()
        var result = loader.loadIfNeeded(
            resource: resource,
            fragmentResource: fragmentResource,
            variables: .init(),
            fetchPolicy: .networkOnly
        )
        expect(result).to(beNil())
        
        advance()
        expect { loader.result }.toEventuallyNot(beNil())
        let snapshot = try loader.result!.get()
        expect(snapshot.isMissingData).to(beFalse())
        
        result = loader.loadIfNeeded(
            resource: resource,
            fragmentResource: fragmentResource,
            variables: .init(),
            fetchPolicy: .networkOnly
        )
        expect(result).toNot(beNil())
        
        var resultWasSet = false
        loader.$result.dropFirst().sink { _ in resultWasSet = true }.store(in: &cancellables)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.2))
        expect(resultWasSet).to(beFalse())
    }
    
    func testDoesNotReloadIfFetchKeyIsUnchanged() throws {
        let fetchKey = UUID()
        
        let advance = try environment.delayMockedResponse(MoviesTabQuery(), MoviesTab.allFilms)
        let loader = QueryLoader<MoviesTabQuery>()
        var result = loader.loadIfNeeded(
            resource: resource,
            fragmentResource: fragmentResource,
            variables: .init(),
            fetchPolicy: .networkOnly,
            fetchKey: fetchKey
        )
        expect(result).to(beNil())
        
        advance()
        expect { loader.result }.toEventuallyNot(beNil())
        let snapshot = try loader.result!.get()
        expect(snapshot.isMissingData).to(beFalse())
        
        result = loader.loadIfNeeded(
            resource: resource,
            fragmentResource: fragmentResource,
            variables: .init(),
            fetchPolicy: .networkOnly,
            fetchKey: fetchKey
        )
        expect(result).toNot(beNil())
        
        var resultWasSet = false
        loader.$result.dropFirst().sink { _ in resultWasSet = true }.store(in: &cancellables)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.2))
        expect(resultWasSet).to(beFalse())
    }
    
    func testReloadsWhenFetchKeyChanges() throws {
        var fetchKey = UUID()
        
        let advance = try environment.delayMockedResponse(MoviesTabQuery(), MoviesTab.allFilms)
        let loader = QueryLoader<MoviesTabQuery>()
        var result = loader.loadIfNeeded(
            resource: resource,
            fragmentResource: fragmentResource,
            variables: .init(),
            fetchPolicy: .networkOnly,
            fetchKey: fetchKey
        )
        expect(result).to(beNil())
        
        advance()
        expect { loader.result }.toEventuallyNot(beNil())
        var snapshot = try loader.result!.get()
        expect(snapshot.isMissingData).to(beFalse())
        
        var resultWasSet = false
        loader.$result.dropFirst().sink { _ in resultWasSet = true }.store(in: &cancellables)

        fetchKey = UUID()
        result = loader.loadIfNeeded(
            resource: resource,
            fragmentResource: fragmentResource,
            variables: .init(),
            fetchPolicy: .networkOnly,
            fetchKey: fetchKey
        )
        expect(result).to(beNil())
        expect(resultWasSet).toEventually(beTrue())
        expect(loader.result).toEventuallyNot(beNil())
        
        snapshot = try loader.result!.get()
        expect(snapshot.isMissingData).to(beFalse())
        
        assertSnapshot(matching: snapshot.data, as: .dump)
    }
    
    func testUpdatesResultForRelevantStoreChanges() throws {
        try environment.mockResponse(CurrentUserToDoListQuery(), CurrentUserToDoList.myTodos)
        let loader = QueryLoader<CurrentUserToDoListQuery>()
        let result = loader.loadIfNeeded(
            resource: resource,
            fragmentResource: fragmentResource,
            variables: .init(),
            fetchPolicy: .networkOnly
        )
        expect(result).to(beNil())
        expect { loader.result }.toEventuallyNot(beNil())
        
        let snapshot = try loader.result!.get()
        assertSnapshot(matching: snapshot.data, as: .dump)
        
        try environment.cachePayload(CurrentUserToDoListQuery(), CurrentUserToDoList.differentUser)
        expect { loader.data?.user?.id }.toEventually(equal("a_new_user_id"))
        assertSnapshot(matching: loader.data, as: .dump)
    }

    func testDoesNotUpdateResultForIrrelevantStoreChanges() throws {
        try environment.mockResponse(CurrentUserToDoListQuery(), CurrentUserToDoList.myTodos)
        let loader = QueryLoader<CurrentUserToDoListQuery>()
        let result = loader.loadIfNeeded(
            resource: resource,
            fragmentResource: fragmentResource,
            variables: .init(),
            fetchPolicy: .networkOnly
        )
        expect(result).to(beNil())
        expect { loader.result }.toEventuallyNot(beNil())

        let snapshot = try loader.result!.get()
        assertSnapshot(matching: snapshot.data, as: .dump)

        var resultWasSet = false
        loader.$result.dropFirst().sink { _ in resultWasSet = true }.store(in: &cancellables)

        try environment.cachePayload(CurrentUserToDoListQuery(), CurrentUserToDoList.otherTodos)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.2))
        expect(resultWasSet).to(beFalse())
        assertSnapshot(matching: loader.data, as: .dump)
    }

    func testHandlesErrorFromTheServer() throws {
        let loader = QueryLoader<MoviesTabQuery>()
        let advance = try environment.delayMockedResponse(MoviesTabQuery(), MoviesTab.error)
        let result = loader.loadIfNeeded(
            resource: resource,
            fragmentResource: fragmentResource,
            variables: .init(),
            fetchPolicy: .networkOnly
        )
        expect(result).to(beNil())

        advance()
        expect { loader.result }.toEventuallyNot(beNil())
        expect { try loader.result!.get() }.to(throwError {
            assertSnapshot(matching: $0, as: .dump)
        })
        expect(loader.error).notTo(beNil())
        expect(loader.data).to(beNil())
        expect(loader.isLoading).to(beFalse())
    }

    func testShowsErrorWhenThereIsExistingStoreData() throws {
        try environment.cachePayload(MoviesTabQuery(), MoviesTab.allFilms)

        let loader = QueryLoader<MoviesTabQuery>()
        let advance = try environment.delayMockedResponse(MoviesTabQuery(), MoviesTab.error)
        let result = loader.loadIfNeeded(
            resource: resource,
            fragmentResource: fragmentResource,
            variables: .init(),
            fetchPolicy: .storeAndNetwork
        )
        expect(result).notTo(beNil())
        expect(loader.data).notTo(beNil())

        var resultWasSet = false
        loader.$result.dropFirst().sink { _ in resultWasSet = true }.store(in: &cancellables)

        advance()
        expect(resultWasSet).toEventually(beTrue())
        
        expect { try loader.result!.get() }.to(throwError {
            assertSnapshot(matching: $0, as: .dump)
        })
        expect(loader.error).notTo(beNil())
        expect(loader.data).to(beNil())
        expect(loader.isLoading).to(beFalse())
    }

    func testAvoidsStoreLookupWhenDataIsMissing() throws {
        try environment.cachePayload(MoviesTabQuery(), MoviesTab.allFilms)
        environment.store.source.remove("ZmlsbXM6Mg==")

        let advance = try environment.delayMockedResponse(MoviesTabQuery(), MoviesTab.allFilms)
        let loader = QueryLoader<MoviesTabQuery>()
        let result = loader.loadIfNeeded(
            resource: resource,
            fragmentResource: fragmentResource,
            variables: .init(),
            fetchPolicy: .storeAndNetwork
        )
        expect(result).to(beNil())

        advance()
        expect { loader.result }.toEventuallyNot(beNil())
        let snapshot = try loader.result!.get()
        expect(snapshot.isMissingData).to(beFalse())

        assertSnapshot(matching: snapshot.data, as: .dump)
    }
}
