import SwiftUI
import Relay

@propertyWrapper
public struct Fragment<F: Relay.Fragment>: DynamicProperty {
    @SwiftUI.Environment(\.relayEnvironment) var environment: Relay.Environment?
    let keyBox = KeyBox()
    @ObservedObject var loader: FragmentLoader<F>

    public init(_ type: F.Type) {
        loader = FragmentLoader()
    }

    public var projectedValue: F.Key {
        get { keyBox.key! }
        nonmutating set { keyBox.key = newValue }
    }

    public var wrappedValue: F.Data? {
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
