import SwiftUI
import Relay

@propertyWrapper
public struct Fragment<F: Relay.Fragment>: DynamicProperty {
    let fragment: F
    @SwiftUI.Environment(\.relayEnvironment) var environment: Relay.Environment?
    let keyBox = KeyBox()
    @ObservedObject var loader: FragmentLoader<F>

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
