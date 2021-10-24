import Combine
import SwiftUI
import Relay

@propertyWrapper
public struct RefetchableFragment<F: Relay.RefetchFragment>: DynamicProperty {
    @SwiftUI.Environment(\.fragmentResource) var fragmentResource
    @SwiftUI.Environment(\.queryResource) var queryResource
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
        loader.load(from: fragmentResource!, queryResource: queryResource!, key: key)

        guard let data = loader.data else {
            return nil
        }

        return Wrapper(data: data, fragment: self)
    }

    @dynamicMemberLookup
    public struct Wrapper: Refetching {
        public let data: F.Data
        let fragment: RefetchableFragment<F>

        public subscript<Subject>(dynamicMember keyPath: KeyPath<F.Data, Subject>) -> Subject {
            return data[keyPath: keyPath]
        }

        @available(iOS 15.0, macOS 12.0, watchOS 7.0, tvOS 15.0, *)
        public func refetch(_ variables: F.Operation.Variables? = nil) async {
            await fragment.loader.refetch(variables, from: fragment.fragmentResource!, queryResource: fragment.queryResource!, key: fragment.key!)
        }
    }
}
