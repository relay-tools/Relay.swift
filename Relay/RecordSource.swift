private let clientIDPrefix = "client:"

public struct DataID: RawRepresentable, ExpressibleByStringLiteral, Hashable {
    public var rawValue: String

    public init(_ value: String) {
        self.rawValue = value
    }

    public init?(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: StringLiteralType) {
        self.rawValue = value
    }

    public static let rootID: DataID = "client:root"
    public static let viewerID = DataID.rootID.clientID(storageKey: "viewer")

    public func clientID(storageKey: String, index: Int? = nil) -> DataID {
        var key = "\(rawValue):\(storageKey)"
        if let index = index {
            key += ":\(index)"
        }
        if !key.hasPrefix(clientIDPrefix) {
            key = clientIDPrefix + key
        }
        return DataID(key)
    }

    public static func generateClientID() -> DataID {
        // Relay does this with an incrementing ID number
        return DataID("\(clientIDPrefix)local:\(UUID().uuidString)")
    }

    public static func get(_ value: [String: Any], typename: String) -> DataID? {
        if typename == viewerType {
            if let id = value["id"] {
                return DataID(id as! String)
            } else {
                return .viewerID
            }
        }
        return value["id"].map { DataID($0 as! String) }
    }
}

public protocol RecordSource {
    subscript(_ dataID: DataID) -> Record? { get set }
    var recordIDs: [DataID] { get }
    // TODO getStatus
    func has(dataID: DataID) -> Bool
    var count: Int { get }
    // TODO toJSON
    mutating func clear()
}

public struct DefaultRecordSource: RecordSource {
    var records = [DataID: Record]()

    public init() {
    }

    public subscript(dataID: DataID) -> Record? {
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
