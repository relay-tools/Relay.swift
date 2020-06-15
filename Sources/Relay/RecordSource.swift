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
    // TODO toJSON
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
