public protocol Operation {
    var node: ConcreteRequest { get }
    associatedtype Variables: Encodable
    associatedtype Response: Decodable
}

extension Operation {
    func createDescriptor(variables: Variables, dataID: DataID = .rootID) -> OperationDescriptor {
        // we don't do anything like Relay in JS does to set the default variables for the
        // operation. Instead, we can just include the default values in the struct definition,
        // so any Variables struct we get should already have its defaults set.

        let node = self.node

        let requestDescriptor = RequestDescriptor(request: node, variables: variables)
        return OperationDescriptor(request: node, variables: variables, requestDescriptor: requestDescriptor, dataID: dataID)
    }
}

struct OperationDescriptor {
    var fragment: SingularReaderSelector
    var request: RequestDescriptor
    var root: NormalizationSelector

    init<Vars: Encodable>(request: ConcreteRequest, variables: Vars, requestDescriptor: RequestDescriptor, dataID: DataID) {
        self.fragment = SingularReaderSelector(dataID: dataID, node: request.fragment, owner: requestDescriptor, variables: AnyEncodable(variables))
        self.request = requestDescriptor
        self.root = NormalizationSelector(dataID: dataID, node: request.operation, variables: AnyEncodable(variables))
    }
}

typealias RequestIdentifier = String

struct RequestDescriptor {
    var identifier: String
    var node: ConcreteRequest
    var variables: AnyEncodable

    init<Vars: Encodable>(request: ConcreteRequest, variables: Vars) {
        self.identifier = request.params.identifier(variables: variables)
        self.node = request
        self.variables = AnyEncodable(variables)
    }
}
