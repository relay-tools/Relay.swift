import Foundation

public protocol Variables: Codable {
    var asDictionary: [String: Any] { get }
}

public struct EmptyVariables: Variables {
    public var asDictionary: [String : Any] { [:] }
}

public struct AnyVariables: Variables {
    private let encode: (Encoder) throws -> Void
    private let dict: () -> [String: Any]

    public init<V: Variables>(_ vars: V) {
        encode = { try vars.encode(to: $0) }
        dict = { vars.asDictionary }
    }

    public init(from decoder: Decoder) throws {
        preconditionFailure("Cannot decode directly into an AnyVariables instance")
    }

    public func encode(to encoder: Encoder) throws {
        try encode(encoder)
    }

    public var asDictionary: [String : Any] {
        dict()
    }
}
