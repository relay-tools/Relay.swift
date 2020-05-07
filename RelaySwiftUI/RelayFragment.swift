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
        RelayFragmentInner(environment: environment!, fragment: fragment, key: key, content: content)
    }
}

struct RelayFragmentInner<Fragment: Relay.Fragment, ContentView: View>: View {
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
        content(loader.data)
    }
}
