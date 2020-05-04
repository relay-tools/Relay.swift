public struct DataID: RawRepresentable, ExpressibleByStringLiteral, Hashable {
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

public struct DefaultRecordSource: RecordSource {
    var records = [DataID: Any]()

    public init() {
    }

    public subscript(dataID: DataID) -> Any? {
        get {
            records[dataID]
        }
        set {
            records[dataID] = newValue
        }
    }

    public var recordIDs: [DataID] {
        Array(records.keys)
    }

    public func has(dataID: DataID) -> Bool {
        records[dataID] != nil
    }

    public var count: Int {
        records.count
    }

    public mutating func clear() {
        records.removeAll()
    }
}
