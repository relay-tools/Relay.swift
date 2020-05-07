public protocol ReaderNode {
    var selections: [ReaderSelection] { get }
}

public struct ReaderFragment: Codable, ReaderNode {
    public var name: String
    public var concreteType: String?
    // TODO metadata
    public var argumentDefinitions: [ReaderArgumentDefinition]
    public var selections: [ReaderSelection]

    public init(name: String,
                concreteType: String? = nil,
                argumentDefinitions: [ReaderArgumentDefinition] = [],
                selections: [ReaderSelection] = []) {
        self.name = name
        self.concreteType = concreteType
        self.argumentDefinitions = argumentDefinitions
        self.selections = selections
    }
}

public struct ReaderArgumentDefinition: Codable {

}

public enum ReaderSelection: Codable {
    case field(ReaderField)
    case fragmentSpread(ReaderFragmentSpread)

    public init(from: Decoder) throws {
        preconditionFailure("not implemented yet")
    }

    public func encode(to encoder: Encoder) throws {
        preconditionFailure("not implemented yet")
    }
}

public protocol ReaderField: Storable {
    var alias: String? { get }
    var name: String { get }
    var storageKey: String? { get }
    var args: [Argument]? { get }
}

extension ReaderField {
    var applicationName: String {
        alias ?? name
    }
}

public struct ReaderLinkedField: ReaderField, ReaderNode {
    public var alias: String?
    public var name: String
    public var storageKey: String?
    public var args: [Argument]?

    public var concreteType: String?
    public var plural: Bool
    public var selections: [ReaderSelection]

    public init(name: String,
                alias: String? = nil,
                storageKey: String? = nil,
                args: [Argument]? = nil,
                concreteType: String? = nil,
                plural: Bool = false,
                selections: [ReaderSelection]) {
        self.name = name
        self.alias = alias
        self.storageKey = storageKey
        self.args = args
        self.concreteType = concreteType
        self.plural = plural
        self.selections = selections
    }
}

public struct ReaderScalarField: ReaderField {
    public var alias: String?
    public var name: String
    public var storageKey: String?
    public var args: [Argument]?

    public init(name: String,
                alias: String? = nil,
                storageKey: String? = nil,
                args: [Argument]? = nil) {
        self.name = name
        self.alias = alias
        self.storageKey = storageKey
        self.args = args
    }
}

public struct ReaderFragmentSpread {
    var name: String
    var args: [Argument]?

    public init(name: String,
                args: [Argument]? = nil) {
        self.name = name
        self.args = args
    }
}

public struct SingularReaderSelector {
    var dataID: DataID
    var node: ReaderFragment
    var owner: RequestDescriptor
    var variables: AnyVariables

    init(dataID: DataID, node: ReaderFragment, owner: RequestDescriptor, variables: AnyVariables) {
        self.dataID = dataID
        self.node = node
        self.owner = owner
        self.variables = variables
    }

    public init(fragment: ReaderFragment, pointer: FragmentPointer) {
        dataID = pointer.id
        node = fragment
        owner = pointer.owner
        variables = AnyVariables(EmptyVariables())
    }
}

public protocol Fragment {
    var node: ReaderFragment { get }
    func getFragmentPointer(_ key: Key) -> FragmentPointer
    
    associatedtype Key
    associatedtype Variables: Relay.Variables
    associatedtype Data: Readable
}
