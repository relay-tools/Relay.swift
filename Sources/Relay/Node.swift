import Foundation

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

    func identifier<Vars: Encodable>(variables: Vars) -> RequestIdentifier {
        guard let requestID = id ?? text else {
            preconditionFailure("Expected request \(name) to have either text or id")
        }

        let encodedVars = try! JSONEncoder().encode(variables)
        return "\(requestID)\(String(data: encodedVars, encoding: .utf8)!)"
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

public struct ConcreteRequest {
    var fragment: ReaderFragment
    var operation: NormalizationOperation
    var params: RequestParameters

    public init(fragment: ReaderFragment, operation: NormalizationOperation, params: RequestParameters) {
        self.fragment = fragment
        self.operation = operation
        self.params = params
    }
}

struct NormalizationSelector {
    var dataID: DataID
    var node: NormalizationNode
    var variables: VariableData
}
