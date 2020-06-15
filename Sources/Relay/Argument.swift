public protocol Argument {
    var name: String { get }
    func value(from variables: VariableData) -> VariableValue
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

    public func value(from variables: VariableData) -> VariableValue {
        value.variableValue
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

    public func value(from variables: VariableData) -> VariableValue {
        variables[dynamicMember: variableName] ?? .null
    }
}

public struct ListValueArgument: Argument {
    public var name: String
    public var items: [Argument?]

    public init(name: String, items: [Argument?] = []) {
        self.name = name
        self.items = items
    }

    public func value(from variables: VariableData) -> VariableValue {
        items.map { item -> VariableValue in
            if let item = item {
                return item.value(from: variables)
            } else {
                return .null
            }
        }.variableValue
    }
}

public struct ObjectValueArgument: Argument {
    public var name: String
    public var fields: [Argument]

    public init(name: String, fields: [Argument] = []) {
        self.name = name
        self.fields = fields
    }

    public func value(from variables: VariableData) -> VariableValue {
        Dictionary(uniqueKeysWithValues: fields.map {
            ($0.name, $0.value(from: variables))
        }).variableValue
    }
}
