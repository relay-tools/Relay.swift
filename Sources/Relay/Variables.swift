import Foundation

@dynamicMemberLookup
public struct VariableData: Encodable, Hashable, CustomStringConvertible, ExpressibleByDictionaryLiteral {
    var fields: [String: VariableValue] = [:]

    public init() {}

    public init(_ data: [String: VariableValueConvertible]) {
        fields = data.mapValues { $0.variableValue }
    }

    public init(dictionaryLiteral elements: (String, VariableValueConvertible)...) {
        self.init()
        for (k, v) in elements {
            fields[k] = v.variableValue
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(fields)
    }

    public var isEmpty: Bool {
        fields.isEmpty
    }

    public subscript(dynamicMember key: String) -> VariableValue? {
        get { fields[key] }
        set { fields[key] = newValue }
    }

    public mutating func merge(_ other: VariableDataConvertible) {
        for (k, v) in other.variableData.fields {
            fields[k] = v
        }
    }

    public var description: String {
        if fields.isEmpty {
            return ""
        }
        
        let varString = fields.keys.sorted().map { k in "\(k):\(fields[k]!)" }.joined(separator: ",")
        return "{\(varString)}"
    }
}

public enum VariableValue: Encodable, Hashable, CustomStringConvertible {
    case null
    case string(String)
    case int(Int)
    case bool(Bool)
    case float(Double)
    case object(VariableData)
    case array([VariableValue])

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null:
            try container.encodeNil()
        case .string(let v):
            try container.encode(v)
        case .int(let v):
            try container.encode(v)
        case .bool(let v):
            try container.encode(v)
        case .float(let v):
            try container.encode(v)
        case .object(let data):
            try container.encode(data)
        case .array(let values):
            try container.encode(values)
        }
    }

    public var description: String {
        switch self {
        case .null:
            return "null"
        case .string(let v):
            return v
        case .int(let v):
            return "\(v)"
        case .bool(let v):
            return "\(v)"
        case .float(let v):
            return "\(v)"
        case .object(let data):
            return "\(data)"
        case .array(let values):
            return "[\(values.map { "\($0)" }.joined(separator: ","))]"
        }
    }
}

public protocol VariableValueConvertible {
    var variableValue: VariableValue { get }
}

public protocol VariableDataConvertible: VariableValueConvertible {
    var variableData: VariableData { get }
}

extension VariableDataConvertible {
    public var variableValue: VariableValue { .object(variableData) }
}

extension VariableValue: VariableValueConvertible {
    public var variableValue: VariableValue { self }
}

extension VariableData: VariableDataConvertible {
    public var variableData: VariableData { self }
}

extension String: VariableValueConvertible {
    public var variableValue: VariableValue { .string(self) }
}

extension Int: VariableValueConvertible {
    public var variableValue: VariableValue { .int(self) }
}

extension Bool: VariableValueConvertible {
    public var variableValue: VariableValue { .bool(self) }
}

extension Double: VariableValueConvertible {
    public var variableValue: VariableValue { .float(self) }
}

extension Optional: VariableValueConvertible where Wrapped: VariableValueConvertible {
    public var variableValue: VariableValue {
        switch self {
        case .none:
            return .null
        case .some(let v):
            return v.variableValue
        }
    }
}

extension Array: VariableValueConvertible where Element: VariableValueConvertible {
    public var variableValue: VariableValue {
        .array(map { $0.variableValue })
    }
}

extension Dictionary: VariableValueConvertible where Key == String, Value: VariableValueConvertible {
    public var variableValue: VariableValue { .object(variableData) }
}

extension Dictionary: VariableDataConvertible where Key == String, Value: VariableValueConvertible {
    public var variableData: VariableData { .init(self) }
}

extension RawRepresentable where RawValue == String {
    public var variableValue: VariableValue { .string(rawValue) }
}

public struct EmptyVariables: VariableDataConvertible {
    public init() {}
    
    public var variableData: VariableData { [:] }
}
