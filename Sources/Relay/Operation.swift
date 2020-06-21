public protocol Operation {
    init(variables: Variables)
    var variables: Variables { get }

    static var node: ConcreteRequest { get }
    associatedtype Variables: VariableDataConvertible
    associatedtype Data: Decodable
}

extension Operation {
    public var node: ConcreteRequest { Self.node }

    public func createDescriptor(dataID: DataID = .rootID) -> OperationDescriptor {
        Self.createDescriptor(variables: variables, dataID: dataID)
    }

    public static func createDescriptor(variables: Variables, dataID: DataID = .rootID) -> OperationDescriptor {
        createDescriptor(variables: variables.variableData, dataID: dataID)
    }

    public static func createDescriptor(variables: VariableData, dataID: DataID = .rootID) -> OperationDescriptor {
        // we don't do anything like Relay in JS does to set the default variables for the
        // operation. Instead, we can just include the default values in the struct definition,
        // so any Variables struct we get should already have its defaults set.

        let node = self.node

        let requestDescriptor = RequestDescriptor(request: node, variables: variables)
        return OperationDescriptor(request: node, variables: variables, requestDescriptor: requestDescriptor, dataID: dataID)
    }
}

extension Operation where Variables == EmptyVariables {
    public init() {
        self.init(variables: EmptyVariables())
    }
}
