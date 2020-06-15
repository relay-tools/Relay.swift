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
            return String(reflecting: v)
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
