public protocol PaginationFragment: RefetchFragment {
}

public enum PaginationDirection: Hashable {
    case forward
    case backward
}

public protocol ConnectionCollection: RandomAccessCollection where Element == Edges.Element.Node {
    associatedtype Edges: RandomAccessCollection where Edges.Element: ConnectionEdge
    var edges: Edges { get }
}

public protocol ConnectionEdge {
    associatedtype Node: ConnectionNode
    var node: Node { get }
}

public protocol ConnectionNode {
    associatedtype NodeType
    var relay_node: NodeType? { get }
}

extension ConnectionCollection {
    public subscript(position: Edges.Index) -> Edges.Element.Node {
        edges[position].node
    }
    
    public var startIndex: Edges.Index {
        edges.startIndex
    }
    
    public var endIndex: Edges.Index {
        edges.endIndex
    }
    
    public func index(before i: Edges.Index) -> Edges.Index {
        edges.index(before: i)
    }
    
    public func index(after i: Edges.Index) -> Edges.Index {
        edges.index(after: i)
    }
}

extension Optional: Sequence where Wrapped: Sequence, Wrapped.Element: ConnectionEdge {
    public typealias Element = Wrapped.Element
    public typealias Iterator = AnyIterator<Wrapped.Element>
    
    public __consuming func makeIterator() -> AnyIterator<Wrapped.Element> {
        if let wrapped = self {
            return AnyIterator(wrapped.makeIterator())
        } else {
            return AnyIterator([].makeIterator())
        }
    }
}

extension Optional: Collection where Wrapped: Collection, Wrapped.Element: ConnectionEdge, Wrapped.Index == Int {
    public subscript(position: Wrapped.Index) -> Wrapped.Element {
        self![position]
    }
    
    public var startIndex: Wrapped.Index {
        self?.startIndex ?? 0
    }
    
    public var endIndex: Wrapped.Index {
        self?.endIndex ?? 0
    }
    
    public func index(after i: Wrapped.Index) -> Wrapped.Index {
        self?.index(after: i) ?? 0
    }
}

extension Optional: BidirectionalCollection where Wrapped: BidirectionalCollection, Wrapped.Element: ConnectionEdge, Wrapped.Index == Int {
    public func index(before i: Wrapped.Index) -> Wrapped.Index {
        self?.index(before: i) ?? 0
    }
}

extension Optional: RandomAccessCollection where Wrapped: RandomAccessCollection, Wrapped.Element: ConnectionEdge, Wrapped.Index == Int {}

extension Optional: ConnectionEdge where Wrapped: ConnectionEdge, Wrapped.Node.NodeType: ConnectionNode {
    public typealias Node = Wrapped.Node.NodeType?
    
    public var node: Wrapped.Node.NodeType? {
        self?.node.relay_node
    }
}

public extension ConnectionNode {
    var relay_node: Self? { self }
}

extension Optional: ConnectionNode where Wrapped: ConnectionNode {
    public var relay_node: Wrapped? { self }
}
