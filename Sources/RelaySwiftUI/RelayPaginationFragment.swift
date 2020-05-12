import Combine
import SwiftUI
import Relay

public struct RelayPaginationFragment<Fragment: Relay.PaginationFragment, ContentView: View>: View {
    public typealias Content = (Fragment.Data?, Paginating) -> ContentView

    @SwiftUI.Environment(\.relayEnvironment) private var environment: Relay.Environment?

    let fragment: Fragment
    let key: Fragment.Key
    let content: Content

    public init(fragment: Fragment,
                key: Fragment.Key,
                content: @escaping Content) {
        self.fragment = fragment
        self.key = key
        self.content = content
    }

    public var body: some View {
        Inner(environment: environment!, fragment: fragment, key: key, content: content)
    }

    struct Inner: View {
        @ObservedObject private var loader: PaginationFragmentLoader<Fragment>
        let fragment: Fragment
        let key: Fragment.Key
        let content: Content

        init(environment: Relay.Environment,
             fragment: Fragment,
             key: Fragment.Key,
             content: @escaping Content) {
            self.fragment = fragment
            self.key = key
            self.content = content
            self.loader = PaginationFragmentLoader(fragment: fragment)

            loader.load(from: environment, key: key)
        }

        var body: some View {
            content(loader.data, loader.paging)
        }
    }
}

@propertyWrapper
public struct PaginationFragment<F: Relay.PaginationFragment>: DynamicProperty {
    @SwiftUI.Environment(\.relayEnvironment) var environment
    let keyBox = KeyBox()
    @ObservedObject var loader: PaginationFragmentLoader<F>

    var cancellable: AnyCancellable?

    public init(_ type: F.Type) {
        loader = PaginationFragmentLoader(fragment: F())
    }

    public var wrappedValue: F.Key {
        get { keyBox.key! }
        set { keyBox.key = newValue }
    }

    public var projectedValue: Wrapper? {
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
