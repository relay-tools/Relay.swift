public protocol Operation {
    init(variables: Variables)
    var variables: Variables { get }

    static var node: ConcreteRequest { get }
    associatedtype Variables: VariableDataConvertible
    associatedtype Data: Readable
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

public struct OperationDescriptor {
    public let fragment: SingularReaderSelector
    public let request: RequestDescriptor
    let root: NormalizationSelector

    init(request: ConcreteRequest, variables: VariableData, requestDescriptor: RequestDescriptor, dataID: DataID) {
        self.fragment = SingularReaderSelector(dataID: dataID, node: request.fragment, owner: requestDescriptor, variables: variables)
        self.request = requestDescriptor
        self.root = NormalizationSelector(dataID: dataID, node: request.operation, variables: variables)
    }
}

typealias RequestIdentifier = String

public struct RequestDescriptor: Hashable {
    var identifier: String
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
