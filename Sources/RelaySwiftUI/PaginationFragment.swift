import Combine
import SwiftUI
import Relay

@propertyWrapper
public struct PaginationFragment<F: Relay.PaginationFragment>: DynamicProperty {
    @SwiftUI.Environment(\.relayEnvironment) var environment
    let keyBox = KeyBox()
    @ObservedObject var loader: PaginationFragmentLoader<F>

    var cancellable: AnyCancellable?

    public init(_ type: F.Type) {
        loader = PaginationFragmentLoader(fragment: F())
    }

    public var projectedValue: F.Key {
        get { keyBox.key! }
        set { keyBox.key = newValue }
    }

    public var wrappedValue: Wrapper? {
        guard let key = keyBox.key else {
            return nil
        }

        // load the data if needed
        loader.load(from: environment!, key: key)

        guard let data = loader.data else {
            return nil
        }

        return Wrapper(data: data, paging: loader.paging)
    }

    @dynamicMemberLookup
    public struct Wrapper: Paginating {
        public let data: F.Data
        let paging: Paginating

        public subscript<Subject>(dynamicMember keyPath: KeyPath<F.Data, Subject>) -> Subject {
            return data[keyPath: keyPath]
        }

        public func loadNext(_ count: Int) {
            paging.loadNext(count)
        }

        public func loadPrevious(_ count: Int) {
            paging.loadPrevious(count)
        }

        public var hasNext: Bool { paging.hasNext }
        public var hasPrevious: Bool { paging.hasPrevious }
        public var isLoadingNext: Bool { paging.isLoadingNext }
        public var isLoadingPrevious: Bool { paging.isLoadingPrevious }
    }

    class KeyBox {
        var key: F.Key?
        init() {}
    }
}
