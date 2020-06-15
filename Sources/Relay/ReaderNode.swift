public protocol ReaderNode {
    var selections: [ReaderSelection] { get }
}

public struct ReaderFragment: ReaderNode {
    public var name: String
    public var type: String
    // TODO metadata
    public var argumentDefinitions: [ReaderArgumentDefinition]
    public var selections: [ReaderSelection]

    public init(name: String,
                type: String,
                argumentDefinitions: [ReaderArgumentDefinition] = [],
                selections: [ReaderSelection] = []) {
        self.name = name
        self.type = type
        self.argumentDefinitions = argumentDefinitions
        self.selections = selections
    }
}

public struct ReaderArgumentDefinition {
}

public enum ReaderSelection {
    case field(ReaderField)
    case fragmentSpread(ReaderFragmentSpread)
    case inlineFragment(ReaderInlineFragment)
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

public struct ReaderInlineFragment {
    var type: String
    var abstractKey: String?
    var selections: [ReaderSelection]

    public init(type: String,
                abstractKey: String? = nil,
                selections: [ReaderSelection] = []) {
        self.type = type
        self.abstractKey = abstractKey
        self.selections = selections
    }
}
