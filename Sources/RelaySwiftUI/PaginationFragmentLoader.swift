import Combine
import Foundation
import Relay

class PaginationFragmentLoader<Fragment: Relay.PaginationFragment>: ObservableObject, Paginating {
    let environment: Environment
    let fragment: Fragment
    let pointer: FragmentPointer
    let metadata: Fragment.Metadata
    let selector: SingularReaderSelector

    @Published var snapshot: Snapshot<Fragment.Data?>

    var subscribeCancellable: AnyCancellable?
    var loadNextCancellable: AnyCancellable?
    var loadPreviousCancellable: AnyCancellable?

    init(environment: Environment,
         fragment: Fragment,
         pointer: FragmentPointer) {
        self.environment = environment
        self.fragment = fragment
        self.pointer = pointer
        self.metadata = fragment.metadata
        self.selector = SingularReaderSelector(fragment: fragment.node, pointer: pointer)

        snapshot = environment.lookup(selector: selector)
    }

    func subscribe() {
        subscribeCancellable = environment.subscribe(snapshot: snapshot)
            .receive(on: DispatchQueue.main)
            .assign(to: \.snapshot, on: self)
    }

    func cancel() {
        subscribeCancellable = nil
    }

    var data: Fragment.Data {
        snapshot.data!
    }

    var paging: Paginating {
        Pager(loader: self)
    }

    func loadNext(_ count: Int) {
        isLoadingNext = true
        loadNextCancellable = loadMore(direction: .forward, count: count).sink(receiveCompletion: { completion in
            self.isLoadingNext = false
            self.loadNextCancellable = nil
        }, receiveValue: { _ in })
    }

    func loadPrevious(_ count: Int) {
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

    @Published var isLoadingNext = false
    @Published var isLoadingPrevious = false

    private func loadMore(direction: PaginationDirection, count: Int) -> AnyPublisher<(), Error> {
        let (cursor, _) = getConnectionState(direction: direction)

        var baseVariables = selector.owner.variables.asDictionary
        baseVariables.merge(selector.variables.asDictionary, uniquingKeysWith: { $1 })

        let paginationVariables = getPaginationVariables(
            direction: direction,
            count: count,
            cursor: cursor,
            baseVariables: baseVariables
        )

        let paginationQuery = metadata.operation.createDescriptor(variables: paginationVariables)

        return environment.execute(operation: paginationQuery, cacheConfig: "TODO")
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
        baseVariables: [String: Any]
    ) -> AnyVariables {
        switch direction {
        case .backward:
            guard let countName = metadata.connection?.backward?.count,
                  let cursorName = metadata.connection?.backward?.cursor else {
                preconditionFailure("Expected backward pagination metadata to be available.")
            }

            var variables = baseVariables
            variables[countName] = count
            variables[cursorName] = cursor

            if let forwardCountName = metadata.connection?.forward?.count {
                variables[forwardCountName] = nil
            }
            if let forwardCursorName = metadata.connection?.forward?.cursor {
                variables[forwardCursorName] = nil
            }

            let data = try! JSONSerialization.data(withJSONObject: variables)
            return AnyVariables(try! JSONDecoder().decode(Fragment.Operation.Variables.self, from: data))
        case .forward:
            guard let countName = metadata.connection?.forward?.count,
                  let cursorName = metadata.connection?.forward?.cursor else {
                preconditionFailure("Expected forward pagination metadata to be available.")
            }

            var variables = baseVariables
            variables[countName] = count
            variables[cursorName] = cursor

            if let backwardCountName = metadata.connection?.backward?.count {
                variables[backwardCountName] = nil
            }
            if let backwardCursorName = metadata.connection?.backward?.cursor {
                variables[backwardCursorName] = nil
            }

            let data = try! JSONSerialization.data(withJSONObject: variables)
            return AnyVariables(try! JSONDecoder().decode(Fragment.Operation.Variables.self, from: data))
        }
    }
}

private struct Pager<Fragment: PaginationFragment>: Paginating {
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
