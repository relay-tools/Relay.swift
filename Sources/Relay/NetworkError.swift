import Foundation

public struct NetworkError: LocalizedError {
    public var errors: [GraphQLError]
    public var operation: ConcreteRequest
    public var variables: VariableData

    public var localizedDescription: String {
        "Network Operation Failed"
    }

    public var failureReason: String? {
        if errors.isEmpty {
            return "No data or errors returned for operation `\(operation.params.name)`"
        } else {
            return "No data returned for operation `\(operation.params.name)`, got \(errors.count == 1 ? "error" : "\(errors.count) errors"):\n" + errors.map { $0.message }.joined(separator: "\n")
        }
    }
}
