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
    func has(_ dataID: DataID) -> Bool
    var count: Int { get }
    // TODO toJSON
    mutating func clear()
}

public struct DefaultRecordSource: RecordSource {
    var records = [DataID: Record]()
    var deletedRecordIDs = Set<DataID>()

    public init() {
    }

    public subscript(_ dataID: DataID) -> Record? {
        get {
            records[dataID]
        }
        set {
            if let value = newValue {
                records[dataID] = value
            } else {
                deletedRecordIDs.insert(dataID)
            }
        }
    }

    public var recordIDs: [DataID] {
        Array(records.keys) + Array(deletedRecordIDs)
    }

    public func has(_ dataID: DataID) -> Bool {
        deletedRecordIDs.contains(dataID) || records[dataID] != nil
    }

    public var count: Int {
        records.count + deletedRecordIDs.count
    }

    public mutating func clear() {
        records.removeAll()
        deletedRecordIDs.removeAll()
    }
}

extension RecordSource {
    mutating func update(from source: RecordSource,
                         currentWriteEpoch: Int,
                         idsMarkedForInvalidation: Set<DataID>? = nil,
                         updatedRecordIDs: inout Set<DataID>,
                         invalidatedRecordIDs: inout Set<DataID>) {
        // TODO ids marked for invalidation

        for dataID in source.recordIDs {
            let sourceRecord = source[dataID]
            let targetRecord = self[dataID]

            if let sourceRecord = sourceRecord, targetRecord != nil {
                self[dataID]!.update(from: sourceRecord)
                updatedRecordIDs.insert(dataID)
            } else if sourceRecord == nil {
                self[dataID] = nil
                if targetRecord != nil {
                    updatedRecordIDs.insert(dataID)
                }
            } else if sourceRecord != nil {
                self[dataID] = sourceRecord
                updatedRecordIDs.insert(dataID)
            }
        }
    }
}
