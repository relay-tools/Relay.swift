/// A proxy for a record in the Relay store.
///
/// Record proxies are used in updater functions to make changes to the records in the Relay store during mutations or
/// client-only updates. See <doc:Updaters> to learn more about updater functions.
public protocol RecordProxy: AnyObject {
    /// The ID of the record.
    ///
    /// All records have a unique ID in the store. If the record has an `id` field, that value will be used as the ID. Otherwise, Relay will choose a client-side ID and use that.
    ///
    /// Because Relay uses that `id` field as a store-wide ID, it's important that you don't use the same IDs for two different values of different types. Your IDs must be globally unique, not just unique within a particular type. One way to do this is to include the type name or an abbreviation of it as part of the ID.
    var dataID: DataID { get }

    /// The name of the schema type for the record.
    ///
    /// Every record in the store belongs to one of the types defined in your GraphQL schema.
    var typeName: String { get }

    subscript(_ name: String, args args: VariableDataConvertible?) -> Any? { get set }
    func getLinkedRecord(_ name: String, args: VariableDataConvertible?) -> RecordProxy?
    func getLinkedRecords(_ name: String, args: VariableDataConvertible?) -> [RecordProxy?]?

    func getOrCreateLinkedRecord(_ name: String, typeName: String, args: VariableDataConvertible?) -> RecordProxy
    func setLinkedRecord(_ name: String, args: VariableDataConvertible?, record: RecordProxy)
    func setLinkedRecords(_ name: String, args: VariableDataConvertible?, records: [RecordProxy?])

    /// Copy all of the fields from another record into this one.
    ///
    /// Copies all of the fields from `record` into `self`. Any fields not present in `record` will be unchanged in `self`. Note that this copies all fields, including linked records.
    ///
    /// - Parameter record: The record to copy fields from.
    func copyFields(from record: RecordProxy)

    /// Mark the record as having invalid data that needs to be refreshed.
    ///
    /// If a record is invalidated, it will still exist in the store, but when a `@Query` is rendered with a ``FetchPolicy/storeOrNetwork`` or ``FetchPolicy/storeAndNetwork`` fetch policy, those records will not be considered valid and will be ignored, requiring a network request to get the latest data. You can use this to ensure your UI doesn't display data that is known to be stale.
    func invalidateRecord()
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

    func getOrCreateLinkedRecord(_ name: String, typeName: String) -> RecordProxy {
        getOrCreateLinkedRecord(name, typeName: typeName, args: nil)
    }

    func setLinkedRecord(_ name: String, record: RecordProxy) {
        setLinkedRecord(name, args: nil, record: record)
    }

    func setLinkedRecords(_ name: String, records: [RecordProxy?]) {
        setLinkedRecords(name, args: nil, records: records)
    }
}

class DefaultRecordProxy: RecordProxy {
    private weak var source: DefaultRecordSourceProxy?
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

        if let source = source,
           let linkedID = mutator.getLinkedRecordID(dataID: dataID, key: storageKey),
           let linkedID2 = linkedID {
            return source[linkedID2]
        } else {
            return nil
        }
    }

    func getLinkedRecords(_ name: String, args: VariableDataConvertible?) -> [RecordProxy?]? {
        let storageKey = formatStorageKey(name: name, variables: args)

        if let source = source,
           let linkedIDs = mutator.getLinkedRecordIDs(dataID: dataID, key: storageKey),
           let linkedIDs2 = linkedIDs {
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
        let linkedRecord = source![clientID] ?? source!.create(dataID: clientID, typeName: typeName)
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
        source?.markIDForInvalidation(dataID)
    }
}
