public protocol Operation {
    var node: ConcreteRequest { get }
    associatedtype Variables: Relay.Variables
    associatedtype Data: Readable
}

extension Operation {
    public func createDescriptor(variables: Variables, dataID: DataID = .rootID) -> OperationDescriptor {
        // we don't do anything like Relay in JS does to set the default variables for the
        // operation. Instead, we can just include the default values in the struct definition,
        // so any Variables struct we get should already have its defaults set.

        let node = self.node

        let requestDescriptor = RequestDescriptor(request: node, variables: variables)
        return OperationDescriptor(request: node, variables: variables, requestDescriptor: requestDescriptor, dataID: dataID)
    }

    public func createDescriptor(variables: AnyVariables, dataID: DataID = .rootID) -> OperationDescriptor {
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

    init<Vars: Variables>(request: ConcreteRequest, variables: Vars, requestDescriptor: RequestDescriptor, dataID: DataID) {
        self.fragment = SingularReaderSelector(dataID: dataID, node: request.fragment, owner: requestDescriptor, variables: AnyVariables(variables))
        self.request = requestDescriptor
        self.root = NormalizationSelector(dataID: dataID, node: request.operation, variables: AnyVariables(variables))
    }
}

typealias RequestIdentifier = String

public struct RequestDescriptor {
    var identifier: String
    var node: ConcreteRequest
    public var variables: AnyVariables

    init<Vars: Variables>(request: ConcreteRequest, variables: Vars) {
        self.identifier = request.params.identifier(variables: variables)
        self.node = request
        self.variables = AnyVariables(variables)
    }
}
