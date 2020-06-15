public protocol VariableDataConvertible: VariableValueConvertible {
    var variableData: VariableData { get }
}

extension VariableDataConvertible {
    public var variableValue: VariableValue { .object(variableData) }
}

extension VariableData: VariableDataConvertible {
    public var variableData: VariableData { self }
}

extension Dictionary: VariableDataConvertible where Key == String, Value: VariableValueConvertible {
    public var variableData: VariableData { .init(self) }
}
