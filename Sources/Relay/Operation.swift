public protocol Operation {
    var node: ConcreteRequest { get }
    associatedtype Variables: VariableDataConvertible
    associatedtype Data: Readable
}

extension Operation {
    public func createDescriptor(variables: Variables, dataID: DataID = .rootID) -> OperationDescriptor {
        createDescriptor(variables: variables.variableData, dataID: dataID)
    }

    public func createDescriptor(variables: VariableData, dataID: DataID = .rootID) -> OperationDescriptor {
        // we don't do anything like Relay in JS does to set the default variables for the
        // operation. Instead, we can just include the default values in the struct definition,
        // so any Variables struct we get should already have its defaults set.

        let node = self.node

        let requestDescriptor = RequestDescriptor(request: node, variables: variables)
        return OperationDescriptor(request: node, variables: variables, requestDescriptor: requestDescriptor, dataID: dataID)
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

public struct RequestDescriptor: Equatable {
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
}
