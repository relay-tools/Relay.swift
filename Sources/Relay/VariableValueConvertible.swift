public protocol VariableValueConvertible {
    var variableValue: VariableValue { get }
}

extension VariableValue: VariableValueConvertible {
    public var variableValue: VariableValue { self }
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

extension RawRepresentable where RawValue == String {
    public var variableValue: VariableValue { .string(rawValue) }
}
