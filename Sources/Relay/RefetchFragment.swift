public protocol RefetchFragment: Fragment {
    associatedtype Operation: Relay.Operation

    typealias Metadata = RefetchMetadata<Operation>

    static var metadata: Metadata { get }
}
