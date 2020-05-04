public struct NormalizationOperation: Codable {
    var name: String
    var argumentDefinitions: [NormalizationLocalArgumentDefinition]
    var selections: [NormalizationSelection]

    public init(name: String, argumentDefinitions: [NormalizationLocalArgumentDefinition] = [], selections: [NormalizationSelection] = []) {
        self.name = name
        self.argumentDefinitions = argumentDefinitions
        self.selections = selections
    }
}

public struct NormalizationLocalArgumentDefinition: Codable {

}

public enum NormalizationSelection: Codable {
    case condition(NormalizationCondition)
    case clientExtension
    case `defer`
    case field(NormalizationField)
    case handle
    case inlineFragment
    case moduleImport
    case stream

    enum CodingKeys: CodingKey {
        case kind
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(String.self, forKey: .kind)

        let superDecoder = try container.superDecoder()

        switch kind {
        case "Condition":
            self = .condition(try NormalizationCondition(from: superDecoder))
        default:
            preconditionFailure("Not sure how to decode a normalization selection with kind \(kind)")
        }

    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .condition(let cond):
            try container.encode("Condition", forKey: .kind)
            try cond.encode(to: container.superEncoder())
        default:
            preconditionFailure("Not sure how to encode this selection")
        }
    }
}

public struct NormalizationCondition: Codable {
    var passingValue: Bool
    var condition: String
    var selections: [NormalizationSelection]
}

public protocol NormalizationField: Codable {
    var alias: String? { get }
    var name: String { get }
    var storageKey: String? { get }
    var args: [NormalizationArgument]? { get }
}

public struct NormalizationLinkedField: NormalizationField {
    public var alias: String?
    public var name: String
    public var storageKey: String?
    public var args: [NormalizationArgument]?

    public var concreteType: String?
    public var plural: Bool
    public var selections: [NormalizationSelection]

    public init(
        name: String,
        alias: String? = nil,
        args: [NormalizationArgument]? = nil,
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
    public var args: [NormalizationArgument]?

    public init(
        name: String,
        alias: String? = nil,
        args: [NormalizationArgument]? = nil,
        storageKey: String? = nil) {
        self.name = name
        self.alias = alias
        self.args = args
        self.storageKey = storageKey
    }
}

public enum NormalizationArgument: Codable {
    // TODO cases

    public init(from decoder: Decoder) throws {
        preconditionFailure("not yet implemented")
    }

    public func encode(to encoder: Encoder) throws {
        preconditionFailure("not yet implemented")
    }
}
