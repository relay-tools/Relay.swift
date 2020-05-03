public struct DataID: RawRepresentable, ExpressibleByStringLiteral {
    public var rawValue: String

    public init?(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: StringLiteralType) {
        self.rawValue = value
    }

    public static let rootID: DataID = "client:root"
}

public protocol RecordSource {
    subscript(_ dataID: DataID) -> Any? { get set }
    var recordIDs: [DataID] { get }
    // TODO getStatus
    func has(dataID: DataID) -> Bool
    var count: Int { get }
    // TODO toJSON
    mutating func clear()
}
