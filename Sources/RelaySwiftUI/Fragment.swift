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

#if swift(>=5.3)
@available(iOS 14.0, macOS 10.16, tvOS 14.0, watchOS 7.0, *)
@propertyWrapper
public struct FragmentNext<F: Relay.Fragment>: DynamicProperty {
    @SwiftUI.Environment(\.relayEnvironment) var environment: Relay.Environment?
    @StateObject var loader = FragmentLoader<F>()
    
    let key: F.Key?

    public init() {
        self.key = nil
    }
    
    public init(_ key: F.Key) {
        self.key = key
    }

    public var wrappedValue: F.Data? {
        guard let key = key else {
            return nil
        }

        // load the data if needed
        loader.load(from: environment!, key: key)

        return loader.data
    }
}
#endif
