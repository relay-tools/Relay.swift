import SwiftUI
import Relay

public struct RelayPaginationFragment<Fragment: Relay.PaginationFragment, ContentView: View>: View {
    @SwiftUI.Environment(\.relayEnvironment) private var environment: Relay.Environment?

    let fragment: Fragment
    let key: Fragment.Key
    let content: (Fragment.Data, Paginating) -> ContentView

    public init(fragment: Fragment,
                key: Fragment.Key,
                content: @escaping (Fragment.Data, Paginating) -> ContentView) {
        self.fragment = fragment
        self.key = key
        self.content = content
    }

    public var body: some View {
        Inner(environment: environment!, fragment: fragment, key: key, content: content)
    }

    struct Inner<Fragment: Relay.PaginationFragment, ContentView: View>: View {
        @ObservedObject private var loader: PaginationFragmentLoader<Fragment>
        let fragment: Fragment
        let key: Fragment.Key
        let content: (Fragment.Data, Paginating) -> ContentView

        init(environment: Relay.Environment,
             fragment: Fragment,
             key: Fragment.Key,
             content: @escaping (Fragment.Data, Paginating) -> ContentView) {
            self.fragment = fragment
            self.key = key
            self.content = content
            self.loader = PaginationFragmentLoader(
                environment: environment,
                fragment: fragment,
                pointer: fragment.getFragmentPointer(key))
        }

        var body: some View {
            Group {
                content(loader.data, loader.paging)
            }
                .onAppear {
                    self.loader.subscribe()
                }
                .onDisappear {
                    self.loader.cancel()
                }
        }
    }
}
