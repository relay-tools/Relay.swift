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
            self.loader = PaginationFragmentLoader(
                environment: environment,
                fragment: fragment,
                pointer: fragment.getFragmentPointer(key))
        }

        var body: some View {
            content(loader.data, loader.paging)
        }
    }
}
