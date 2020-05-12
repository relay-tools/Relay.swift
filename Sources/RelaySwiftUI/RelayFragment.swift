import SwiftUI
import Relay

public struct RelayFragment<Fragment: Relay.Fragment, ContentView: View>: View {
    public typealias Content = (Fragment.Data?) -> ContentView

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
        @ObservedObject private var loader: FragmentLoader<Fragment>
        let content: Content

        init(environment: Relay.Environment,
             fragment: Fragment,
             key: Fragment.Key,
             content: @escaping Content) {
            self.content = content
            self.loader = FragmentLoader(fragment: fragment)

            loader.load(from: environment, key: key)
        }

        var body: some View {
            content(loader.data)
        }
    }
}

@propertyWrapper
public struct Fragment<F: Relay.Fragment>: DynamicProperty {
    let fragment: F
    @SwiftUI.Environment(\.relayEnvironment) var environment: Relay.Environment?
    let keyBox = KeyBox()
    var loader: FragmentLoader<F>

    public init(_ type: F.Type) {
        fragment = F()
        loader = FragmentLoader(fragment: fragment)
    }

    public var wrappedValue: F.Key {
        get { keyBox.key! }
        nonmutating set { keyBox.key = newValue }
    }

    public var projectedValue: F.Data? {
        guard let key = keyBox.key else {
            return nil
        }

        // load the data if needed
        loader.load(from: environment!, key: key)

        return loader.data
    }

    class KeyBox {
        var key: F.Key?
        init() {}
    }
}
