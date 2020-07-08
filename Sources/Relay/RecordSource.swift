public enum RecordState {
    case existent
    case nonexistent
    case unknown
}

public protocol RecordSource {
    subscript(_ dataID: DataID) -> Record? { get set }
    var recordIDs: [DataID] { get }
    func getStatus(_ dataID: DataID) -> RecordState
    func has(_ dataID: DataID) -> Bool
    var count: Int { get }
    mutating func remove(_ dataID: DataID)
    mutating func clear()
}

public struct DefaultRecordSource: RecordSource {
    var records = [DataID: Record]()
    var deletedRecordIDs = Set<DataID>()

    public init() {}

    public subscript(_ dataID: DataID) -> Record? {
        get {
            records[dataID]
        }
        set {
            if let value = newValue {
                records[dataID] = value
                deletedRecordIDs.remove(dataID)
            } else {
                records.removeValue(forKey: dataID)
                deletedRecordIDs.insert(dataID)
            }
        }
    }

    public var recordIDs: [DataID] {
        Array(records.keys) + Array(deletedRecordIDs)
    }

    public func getStatus(_ dataID: DataID) -> RecordState {
        if deletedRecordIDs.contains(dataID) {
            return .nonexistent
        }

        if records[dataID] != nil {
            return .existent
        }

        return .unknown
    }

    public func has(_ dataID: DataID) -> Bool {
        deletedRecordIDs.contains(dataID) || records[dataID] != nil
    }

    public var count: Int {
        records.count + deletedRecordIDs.count
    }

    public mutating func remove(_ dataID: DataID) {
        deletedRecordIDs.remove(dataID)
        records.removeValue(forKey: dataID)
    }

    public mutating func clear() {
        records.removeAll()
        deletedRecordIDs.removeAll()
    }
}

extension RecordSource {
    mutating func update(from source: RecordSource,
                         currentWriteEpoch: Int,
                         idsMarkedForInvalidation: Set<DataID> = [],
                         updatedRecordIDs: inout Set<DataID>,
                         invalidatedRecordIDs: inout Set<DataID>) {
        for dataID in idsMarkedForInvalidation {
            if source.getStatus(dataID) == .nonexistent {
                continue
            }

            var nextRecord: Record
            if let targetRecord = self[dataID] {
                nextRecord = targetRecord
            } else if let sourceRecord = source[dataID] {
                nextRecord = sourceRecord
            } else {
                continue
            }

            nextRecord.invalidatedAt = currentWriteEpoch
            invalidatedRecordIDs.insert(dataID)
            self[dataID] = nextRecord
        }

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

extension DefaultRecordSource: Codable {
    enum CodingKeys: String, CodingKey {
        case records
        case deletedRecordIDs
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        records = Dictionary(
            uniqueKeysWithValues: try container.decode([String: Record].self, forKey: .records).map { key, value in
                (DataID(key), value)
            }
        )
        deletedRecordIDs = try container.decode(Set<DataID>.self, forKey: .deletedRecordIDs)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(
            Dictionary(uniqueKeysWithValues: records.map { key, value in
                (key.rawValue, value)
            }),
            forKey: .records
        )
        try container.encode(deletedRecordIDs.sorted(), forKey: .deletedRecordIDs)
    }
}
