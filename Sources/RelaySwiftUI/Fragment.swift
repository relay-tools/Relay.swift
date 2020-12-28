import SwiftUI
import Relay

@propertyWrapper
public struct Fragment<F: Relay.Fragment>: DynamicProperty {
    @SwiftUI.Environment(\.fragmentResource) var fragmentResource
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
        loader.load(from: fragmentResource!, key: key)

        return loader.data
    }
}
