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
    case clientExtension(NormalizationClientExtension)
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
    public var handleArgs: [Argument]?

    public init(
        kind: Kind,
        name: String,
        alias: String? = nil,
        args: [Argument]? = nil,
        handle: String,
        key: String,
        filters: [String]? = nil,
        handleArgs: [Argument]? = nil) {
        self.kind = kind
        self.name = name
        self.alias = alias
        self.args = args
        self.handle = handle
        self.key = key
        self.filters = filters
        self.handleArgs = handleArgs
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

    func clonedSourceField(selections: [NormalizationSelection], variables: VariableData) -> NormalizationLinkedField {
        precondition(kind == .linked, "clonedSourceField should only be used for linked handles")

        let linkedFields = selections.compactMap { selection -> NormalizationLinkedField? in
            if case .field(let field) = selection, let field2 = field as? NormalizationLinkedField {
                return field2
            }
            return nil
        }
        guard let sourceField = linkedFields.first(where: {
            // TODO check args somehow
            $0.name == name && $0.alias == alias
        }) else {
            preconditionFailure("Expected a corresponding source field for handle `\(handle)`")
        }

        let handleKey = self.handleKey(from: variables)
        return NormalizationLinkedField(
            name: handleKey,
            alias: sourceField.alias,
            storageKey: handleKey,
            concreteType: sourceField.concreteType,
            plural: sourceField.plural,
            selections: sourceField.selections)
    }
}

public struct NormalizationInlineFragment: NormalizationNode {
    public var type: String
    public var abstractKey: String?
    public var selections: [NormalizationSelection]

    public init(type: String,
                abstractKey: String? = nil,
                selections: [NormalizationSelection] = []) {
        self.type = type
        self.abstractKey = abstractKey
        self.selections = selections
    }
}

public struct NormalizationClientExtension: NormalizationNode {
    public var selections: [NormalizationSelection]

    public init(selections: [NormalizationSelection] = []) {
        self.selections = selections
    }
}
