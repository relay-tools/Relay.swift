public struct RequestParameters: Codable {
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
}

public enum OperationKind: String, Codable {
    case mutation
    case query
    case subscription
}

public enum GeneratedNode {
    case request(ConcreteRequest)
}

public struct ConcreteRequest: Codable {
    var fragment: ReaderFragment
    var operation: NormalizationOperation
    var params: RequestParameters

    public init(fragment: ReaderFragment, operation: NormalizationOperation, params: RequestParameters) {
        self.fragment = fragment
        self.operation = operation
        self.params = params
    }
}

public struct ReaderFragment: Codable {
    public init() {}
}

