public protocol Fragment {
    init(key: Key)
    var fragmentPointer: FragmentPointer { get }

    static var node: ReaderFragment { get }

    associatedtype Key
    associatedtype Data: Decodable
}

public extension Fragment {
    var node: ReaderFragment { Self.node }

    var selector: SingularReaderSelector {
        SingularReaderSelector(fragment: node, pointer: fragmentPointer)
    }
}
