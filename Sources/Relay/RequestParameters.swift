public struct RequestParameters {
    public var name: String
    public var operationKind: OperationKind
//    public var metadata: [String: Any] = [:]
    public var text: String?
    public var id: String?

    public init(name: String, operationKind: OperationKind, text: String? = nil, id: String? = nil) {
        self.name = name
        self.operationKind = operationKind
        self.text = text
        self.id = id
    }

    func identifier(variables: VariableData) -> RequestIdentifier {
        guard let requestID = id ?? text else {
            preconditionFailure("Expected request \(name) to have either text or id")
        }

        return "\(requestID)\(variables)"
    }
}

public enum OperationKind: String {
    case mutation
    case query
    case subscription
}
