import Combine
import SwiftUI
import Relay

#if swift(>=5.3)
@available(iOS 14.0, macOS 10.16, tvOS 14.0, watchOS 7.0, *)
@propertyWrapper
public struct RefetchableFragment<F: Relay.RefetchFragment>: DynamicProperty {
    @SwiftUI.Environment(\.relayEnvironment) var environment
    @StateObject var loader = RefetchFragmentLoader<F>()

    let key: F.Key?

    public init() {
        self.key = nil
    }

    public init(_ key: F.Key) {
        self.key = key
    }

    public var wrappedValue: Wrapper? {
        guard let key = key else {
            return nil
        }

        // load the data if needed
        loader.load(from: environment!, key: key)

        guard let data = loader.data else {
            return nil
        }

        return Wrapper(data: data, refetching: loader)
    }

    @dynamicMemberLookup
    public struct Wrapper: Refetching {
        public let data: F.Data
        let refetching: RefetchFragmentLoader<F>

        public subscript<Subject>(dynamicMember keyPath: KeyPath<F.Data, Subject>) -> Subject {
            return data[keyPath: keyPath]
        }

        public func refetch(_ variables: F.Operation.Variables? = nil) {
            refetching.refetch(variables)
        }
    }
}
#endif
