import Foundation

public struct GraphQLError: LocalizedError {
    public var message: String

    public init(message: String) {
        self.message = message
    }

    init?(dictionary data: [String: Any]) {
        guard let message = data["message"] as? String else {
            return nil
        }

        self.message = message
    }

    public var errorDescription: String? {
        return message
    }
}
