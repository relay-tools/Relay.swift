public protocol Argument {
    var name: String { get }
}

public struct LiteralArgument: Argument {
    public var name: String
    public var type: String?
    public var value: VariableValueConvertible

    public init(name: String, type: String? = nil, value: VariableValueConvertible) {
        self.name = name
        self.type = type
        self.value = value
    }
}

public struct VariableArgument: Argument {
    public var name: String
    public var type: String?
    public var variableName: String

    public init(name: String, type: String? = nil, variableName: String) {
        self.name = name
        self.type = type
        self.variableName = variableName
    }
}

public struct ListValueArgument: Argument {
    public var name: String
    public var items: [Argument?]
}

public struct ObjectValueArgument: Argument {
    public var name: String
    public var fields: [Argument]
}
