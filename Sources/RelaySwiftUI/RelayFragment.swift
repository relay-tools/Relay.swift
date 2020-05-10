import SwiftUI
import Relay

public struct RelayFragment<Fragment: Relay.Fragment, ContentView: View>: View {
    @SwiftUI.Environment(\.relayEnvironment) private var environment: Relay.Environment?

    let fragment: Fragment
    let key: Fragment.Key
    let content: (Fragment.Data) -> ContentView

    public init(fragment: Fragment,
                key: Fragment.Key,
                content: @escaping (Fragment.Data) -> ContentView) {
        self.fragment = fragment
        self.key = key
        self.content = content
    }

    public var body: some View {
        Inner(environment: environment!, fragment: fragment, key: key, content: content)
    }

    struct Inner<Fragment: Relay.Fragment, ContentView: View>: View {
        @ObservedObject private var loader: FragmentLoader<Fragment>
        let fragment: Fragment
        let key: Fragment.Key
        let content: (Fragment.Data) -> ContentView

        init(environment: Relay.Environment,
             fragment: Fragment,
             key: Fragment.Key,
             content: @escaping (Fragment.Data) -> ContentView) {
            self.fragment = fragment
            self.key = key
            self.content = content
            self.loader = FragmentLoader(
                environment: environment,
                fragment: fragment,
                pointer: fragment.getFragmentPointer(key))
        }

        var body: some View {
            Group {
                content(loader.data)
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
