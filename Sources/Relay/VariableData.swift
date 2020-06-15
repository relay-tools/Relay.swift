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

    var innerDescription: String {
        if fields.isEmpty {
            return ""
        }

        return fields.keys.sorted().map { k in "\(k):\(fields[k]!)" }.joined(separator: ",")
    }

    public var description: String {
        if fields.isEmpty {
            return ""
        }

        return "{\(innerDescription)}"
    }
}
