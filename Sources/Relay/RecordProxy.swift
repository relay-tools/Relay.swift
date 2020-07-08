public protocol RecordProxy {
    var dataID: DataID { get }
    var typeName: String { get }
    subscript(_ name: String, args args: VariableDataConvertible?) -> Any? { get set }
    func getLinkedRecord(_ name: String, args: VariableDataConvertible?) -> RecordProxy?
    func getLinkedRecords(_ name: String, args: VariableDataConvertible?) -> [RecordProxy?]?

    mutating func getOrCreateLinkedRecord(_ name: String, typeName: String, args: VariableDataConvertible?) -> RecordProxy
    mutating func setLinkedRecord(_ name: String, args: VariableDataConvertible?, record: RecordProxy)
    mutating func setLinkedRecords(_ name: String, args: VariableDataConvertible?, records: [RecordProxy?])

    mutating func copyFields(from record: RecordProxy)
    mutating func invalidateRecord()
}

public extension RecordProxy {
    subscript(_ name: String) -> Any? {
        get { self[name, args: nil] }
        set { self[name, args: nil] = newValue }
    }

    func getLinkedRecord(_ name: String) -> RecordProxy? {
        return getLinkedRecord(name, args: nil)
    }

    func getLinkedRecords(_ name: String) -> [RecordProxy?]? {
        getLinkedRecords(name, args: nil)
    }

    mutating func getOrCreateLinkedRecord(_ name: String, typeName: String) -> RecordProxy {
        getOrCreateLinkedRecord(name, typeName: typeName, args: nil)
    }

    mutating func setLinkedRecord(_ name: String, record: RecordProxy) {
        setLinkedRecord(name, args: nil, record: record)
    }

    mutating func setLinkedRecords(_ name: String, records: [RecordProxy?]) {
        setLinkedRecords(name, args: nil, records: records)
    }
}

class DefaultRecordProxy: RecordProxy {
    private let source: DefaultRecordSourceProxy
    private let mutator: RecordSourceMutator

    var dataID: DataID

    init(source: DefaultRecordSourceProxy, mutator: RecordSourceMutator, dataID: DataID) {
        self.source = source
        self.mutator = mutator
        self.dataID = dataID
    }

    var typeName: String {
        mutator.getType(dataID)!
    }

    subscript(name: String, args args: VariableDataConvertible?) -> Any? {
        get {
            let storageKey = formatStorageKey(name: name, variables: args)
            return mutator.getValue(dataID: dataID, key: storageKey)
        }
        set {
            let storageKey = formatStorageKey(name: name, variables: args)
            mutator.setValue(dataID: dataID, key: storageKey, value: newValue)
        }
    }

    func getLinkedRecord(_ name: String, args: VariableDataConvertible?) -> RecordProxy? {
        let storageKey = formatStorageKey(name: name, variables: args)

        if let linkedID = mutator.getLinkedRecordID(dataID: dataID, key: storageKey), let linkedID2 = linkedID {
            return source[linkedID2]
        } else {
            return nil
        }
    }

    func getLinkedRecords(_ name: String, args: VariableDataConvertible?) -> [RecordProxy?]? {
        let storageKey = formatStorageKey(name: name, variables: args)

        if let linkedIDs = mutator.getLinkedRecordIDs(dataID: dataID, key: storageKey), let linkedIDs2 = linkedIDs {
            return linkedIDs2.map { $0.flatMap { source[$0] } }
        } else {
            return nil
        }
    }

    func getOrCreateLinkedRecord(_ name: String, typeName: String, args: VariableDataConvertible?) -> RecordProxy {
        if let linkedRecord = getLinkedRecord(name, args: args) {
            return linkedRecord
        }

        let storageKey = formatStorageKey(name: name, variables: args)
        let clientID = dataID.clientID(storageKey: storageKey)
        let linkedRecord = source[clientID] ?? source.create(dataID: clientID, typeName: typeName)
        setLinkedRecord(name, args: args, record: linkedRecord)
        return linkedRecord
    }

    func setLinkedRecord(_ name: String, args: VariableDataConvertible?, record: RecordProxy) {
        let storageKey = formatStorageKey(name: name, variables: args)
        mutator.setLinkedRecordID(dataID: dataID, key: storageKey, linkedID: record.dataID)
    }

    func setLinkedRecords(_ name: String, args: VariableDataConvertible?, records: [RecordProxy?]) {
        let storageKey = formatStorageKey(name: name, variables: args)
        let linkedIDs = records.map { $0?.dataID }
        mutator.setLinkedRecordIDs(dataID: dataID, key: storageKey, linkedIDs: linkedIDs)
    }

    func copyFields(from record: RecordProxy) {
        mutator.copyFields(from: record.dataID, to: dataID)
    }

    func invalidateRecord() {
        source.markIDForInvalidation(dataID)
    }
}
