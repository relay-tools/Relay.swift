public struct EmptyVariables: VariableDataConvertible {
    public init() {}
    
    public var variableData: VariableData { [:] }
}
