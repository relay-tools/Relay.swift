import Combine
import Foundation
import Relay

class PaginationFragmentLoader<Fragment: Relay.PaginationFragment>: ObservableObject, Paginating {
    let metadata: Fragment.Metadata

    var environment: Environment!
    var selector: SingularReaderSelector!

    var snapshot: Snapshot<Fragment.Data?>? {
        // not sure why this is needed instead of using Published.
        // my best guess is it's because it's optional, and that adds indirection to the value.
        willSet {
            self.objectWillChange.send()
        }
    }

    var subscribeCancellable: AnyCancellable?
    var loadNextCancellable: AnyCancellable?
    var loadPreviousCancellable: AnyCancellable?

    init() {
        self.metadata = Fragment.metadata
    }

    private var isLoaded = false

    func load(from environment: Environment, key: Fragment.Key) {
        guard !isLoaded else { return }

        self.environment = environment
        self.selector = Fragment(key: key).selector
        snapshot = environment.lookup(selector: selector)
        subscribe()

        isLoaded = true
    }

    func subscribe() {
        guard let snapshot = snapshot else { return }

        subscribeCancellable = environment.subscribe(snapshot: snapshot)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] snapshot in
                self?.snapshot = snapshot
            }
    }

    var data: Fragment.Data? {
        guard let snapshot = snapshot else { return nil }

        if snapshot.isMissingData && environment.isActive(request: snapshot.selector.owner) {
            // wait for the request to finish to try to get complete data.
            // this can happen if we are loading query data from the store and we change the
            // query variables, such that some of the records in the tree still exist but not
            // all.
            return nil
        }

        return snapshot.data
    }

    var paging: Paginating {
        Pager(loader: self)
    }

    func loadNext(_ count: Int) {
        guard !isLoadingNext else { return }

        isLoadingNext = true
        loadNextCancellable = loadMore(direction: .forward, count: count).sink(receiveCompletion: { completion in
            self.isLoadingNext = false
            self.loadNextCancellable = nil
        }, receiveValue: { _ in })
    }

    func loadPrevious(_ count: Int) {
        guard !isLoadingPrevious else { return }
        
        isLoadingPrevious = true
        loadPreviousCancellable = loadMore(direction: .backward, count: count).sink(receiveCompletion: { completion in
            self.isLoadingPrevious = false
            self.loadPreviousCancellable = nil
        }, receiveValue: { _ in })
    }

    var hasNext: Bool {
        let (_, hasMore) = getConnectionState(direction: .forward)
        return hasMore
    }

    var hasPrevious: Bool {
        let (_, hasMore) = getConnectionState(direction: .backward)
        return hasMore
    }

    var isLoadingNext = false {
        willSet {
            objectWillChange.send()
        }
    }
    var isLoadingPrevious = false {
        willSet {
            objectWillChange.send()
        }
    }

    private func loadMore(direction: PaginationDirection, count: Int) -> AnyPublisher<(), Error> {
        let (cursor, _) = getConnectionState(direction: direction)

        var baseVariables = selector.owner.variables
        baseVariables.merge(selector.variables)

        let paginationVariables = getPaginationVariables(
            direction: direction,
            count: count,
            cursor: cursor,
            baseVariables: baseVariables
        )

        let paginationQuery = metadata.operation.createDescriptor(variables: paginationVariables)

        return environment.execute(operation: paginationQuery, cacheConfig: CacheConfig())
            .receive(on: DispatchQueue.main)
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    private func getConnectionState(direction: PaginationDirection) -> (String?, Bool) {
        let data: SelectorData? = environment.lookup(selector: selector).data

        guard let maybeConnection = data?.get(path: metadata.connection!.pathInFragment) as? SelectorData? else {
            preconditionFailure("Expected connection to be either null or a plain object")
        }
        guard let connection = maybeConnection else {
            return (nil, false)
        }

        guard
            connection.get([SelectorData?]?.self, ConnectionConfig.default.edges) != nil,
            let pageInfo = connection.get(SelectorData?.self, ConnectionConfig.default.pageInfo) else {
            return (nil, false)
        }

        let cursorField = direction == .forward ? ConnectionConfig.default.endCursor : ConnectionConfig.default.startCursor
        let cursor = pageInfo.get(String?.self, cursorField)

        let hasMoreField = direction == .forward ? ConnectionConfig.default.hasNextPage : ConnectionConfig.default.hasPreviousPage
        let hasMore = cursor != nil && pageInfo.get(Bool.self, hasMoreField)

        return (cursor, hasMore)
    }

    private func getPaginationVariables(
        direction: PaginationDirection,
        count: Int,
        cursor: String?,
        baseVariables: VariableData
    ) -> VariableData {
        switch direction {
        case .backward:
            guard let countName = metadata.connection?.backward?.count,
                  let cursorName = metadata.connection?.backward?.cursor else {
                preconditionFailure("Expected backward pagination metadata to be available.")
            }

            var variables = baseVariables
            variables[dynamicMember: countName] = .int(count)
            variables[dynamicMember: cursorName] = cursor.map { .string($0) }

            if let forwardCountName = metadata.connection?.forward?.count {
                variables[dynamicMember: forwardCountName] = nil
            }
            if let forwardCursorName = metadata.connection?.forward?.cursor {
                variables[dynamicMember: forwardCursorName] = nil
            }

            return variables
        case .forward:
            guard let countName = metadata.connection?.forward?.count,
                  let cursorName = metadata.connection?.forward?.cursor else {
                preconditionFailure("Expected forward pagination metadata to be available.")
            }

            var variables = baseVariables
            variables[dynamicMember: countName] = .int(count)
            variables[dynamicMember: cursorName] = cursor.map { .string($0) }

            if let backwardCountName = metadata.connection?.backward?.count {
                variables[dynamicMember: backwardCountName] = nil
            }
            if let backwardCursorName = metadata.connection?.backward?.cursor {
                variables[dynamicMember: backwardCursorName] = nil
            }

            return variables
        }
    }
}

private struct Pager<Fragment: Relay.PaginationFragment>: Paginating {
    let hasNext: Bool
    let hasPrevious: Bool
    let isLoadingNext: Bool
    let isLoadingPrevious: Bool
    let loader: PaginationFragmentLoader<Fragment>

    init(loader: PaginationFragmentLoader<Fragment>) {
        hasNext = loader.hasNext
        hasPrevious = loader.hasPrevious
        isLoadingNext = loader.isLoadingNext
        isLoadingPrevious = loader.isLoadingPrevious
        self.loader = loader
    }

    func loadNext(_ count: Int) {
        loader.loadNext(count)
    }

    func loadPrevious(_ count: Int) {
        loader.loadPrevious(count)
    }
}

public protocol Paginating {
    func loadNext(_ count: Int)
    func loadPrevious(_ count: Int)
    var hasNext: Bool { get }
    var hasPrevious: Bool { get }
    var isLoadingNext: Bool { get }
    var isLoadingPrevious: Bool { get }
}
