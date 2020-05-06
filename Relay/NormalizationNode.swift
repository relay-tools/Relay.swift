public protocol NormalizationNode {
    var selections: [NormalizationSelection] { get }
}

public struct NormalizationOperation: NormalizationNode {
    public var name: String
    public var argumentDefinitions: [NormalizationLocalArgumentDefinition]
    public var selections: [NormalizationSelection]

    public init(name: String, argumentDefinitions: [NormalizationLocalArgumentDefinition] = [], selections: [NormalizationSelection] = []) {
        self.name = name
        self.argumentDefinitions = argumentDefinitions
        self.selections = selections
    }
}

public struct NormalizationLocalArgumentDefinition {

}

public enum NormalizationSelection {
    case condition(NormalizationCondition)
    case clientExtension
    case `defer`
    case field(NormalizationField)
    case handle
    case inlineFragment(NormalizationInlineFragment)
    case moduleImport
    case stream

    enum CodingKeys: CodingKey {
        case kind
    }
}

public struct NormalizationCondition {
    var passingValue: Bool
    var condition: String
    var selections: [NormalizationSelection]
}

public protocol NormalizationField: Storable {
    var alias: String? { get }
    var name: String { get }
    var storageKey: String? { get }
    var args: [Argument]? { get }
}

extension NormalizationField {
    var responseKey: String {
        alias ?? name
    }
}

public struct NormalizationLinkedField: NormalizationField, NormalizationNode {
    public var alias: String?
    public var name: String
    public var storageKey: String?
    public var args: [Argument]?

    public var concreteType: String?
    public var plural: Bool
    public var selections: [NormalizationSelection]

    public init(
        name: String,
        alias: String? = nil,
        args: [Argument]? = nil,
        storageKey: String? = nil,
        concreteType: String? = nil,
        plural: Bool = false,
        selections: [NormalizationSelection] = []) {
        self.name = name
        self.alias = alias
        self.args = args
        self.storageKey = storageKey
        self.concreteType = concreteType
        self.plural = plural
        self.selections = selections
    }
}

public struct NormalizationScalarField: NormalizationField {
    public var alias: String?
    public var name: String
    public var storageKey: String?
    public var args: [Argument]?

    public init(
        name: String,
        alias: String? = nil,
        args: [Argument]? = nil,
        storageKey: String? = nil) {
        self.name = name
        self.alias = alias
        self.args = args
        self.storageKey = storageKey
    }
}

public struct NormalizationInlineFragment: NormalizationNode {
    public var type: String
    public var selections: [NormalizationSelection]

    public init(type: String, selections: [NormalizationSelection] = []) {
        self.type = type
        self.selections = selections
    }
}
