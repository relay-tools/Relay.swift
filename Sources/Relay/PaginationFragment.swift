public protocol PaginationFragment: Fragment {
    associatedtype Operation: Relay.Operation

    typealias Metadata = RefetchMetadata<Operation>

    static var metadata: Metadata { get }
}

public enum PaginationDirection: Hashable {
    case forward
    case backward
}
