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
    case handle(NormalizationHandle)
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

public struct NormalizationHandle: Storable {
    public enum Kind {
        case scalar
        case linked
    }

    public var kind: Kind
    public var name: String
    public var alias: String?
    public var args: [Argument]?
    public var handle: String
    public var key: String
    // TODO dynamicKey? Not sure what this does
    public var filters: [String]?

    public init(
        kind: Kind,
        name: String,
        alias: String? = nil,
        args: [Argument]? = nil,
        handle: String,
        key: String,
        filters: [String]? = nil) {
        self.kind = kind
        self.name = name
        self.alias = alias
        self.args = args
        self.handle = handle
        self.key = key
        self.filters = filters
    }

    public var storageKey: String? { nil }

    func handleKey(from variables: VariableData) -> String {
        let handleName = getRelayHandleKey(handleName: handle, key: key, fieldName: name)
        var filterArgs: [Argument]?
        if let args = args, let filters = filters, !args.isEmpty, !filters.isEmpty {
            filterArgs = args.filter { filters.contains($0.name) }
        }
        // TODO dynamicKey
        if let filterArgs = filterArgs {
            return formatStorageKey(name: handleName, variables: getArgumentValues(filterArgs, variables))
        } else {
            return handleName
        }
    }
}
