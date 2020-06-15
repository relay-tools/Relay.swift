typealias RequestIdentifier = String

public struct RequestDescriptor: Hashable {
    var identifier: RequestIdentifier
    var node: ConcreteRequest
    public var variables: VariableData

    init(request: ConcreteRequest, variables: VariableData) {
        self.identifier = request.params.identifier(variables: variables)
        self.node = request
        self.variables = variables
    }

    public static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.identifier == rhs.identifier && lhs.variables == rhs.variables
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
        hasher.combine(variables)
    }
}
