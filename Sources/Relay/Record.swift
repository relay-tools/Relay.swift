import Foundation

let viewerType = "Viewer"

public struct Record: Equatable {
    public static let root = Record(dataID: .rootID, typename: "__Root")

    public var dataID: DataID
    public var typename: String

    private var fields: [String: Value] = [:]

    public init(dataID: DataID,
                typename: String,
                values: [String: Any] = [:],
                linkedRecordIDs: [String: DataID] = [:],
                linkedPluralRecordIDs: [String: [DataID?]] = [:]) {
        self.dataID = dataID
        self.typename = typename
        for (k, v) in values {
            self[k] = v
        }
        for (k, v) in linkedRecordIDs {
            self.setLinkedRecordID(k, v)
        }
        for (k, v) in linkedPluralRecordIDs {
            self.setLinkedRecordIDs(k, v)
        }
    }

    private enum Value: Equatable, CustomDebugStringConvertible {
        case null
        case int(Int)
        case float(Double)
        case string(String)
        case bool(Bool)
        case array([Value?])
        case linkedRecord(DataID)
        case linkedRecords([DataID?])

        init?(scalar: Any) {
            if scalar is NSNull {
                self = .null
            } else if let v = scalar as? Int {
                self = .int(v)
            } else if let v = scalar as? Double {
                self = .float(v)
            } else if let v = scalar as? String {
                self = .string(v)
            } else if let v = scalar as? Bool {
                self = .bool(v)
            } else if let v = scalar as? [Any?] {
                let values = v.map { $0.flatMap { Value(scalar: $0) } }
                self = .array(values)
            } else {
                return nil
            }
        }

        var scalar: Any? {
            switch self {
            case .null:
                return NSNull()
            case .int(let v):
                return v
            case .float(let v):
                return v
            case .string(let v):
                return v
            case .bool(let v):
                return v
            case .array(let values):
                return values.map { $0?.scalar }
            case .linkedRecord, .linkedRecords:
                return nil
            }
        }

        var debugDescription: String {
            if let v = scalar {
                return String(reflecting: v)
            } else if case .linkedRecord(let id) = self {
                return ".linkedRecord(\(id.rawValue))"
            } else if case .linkedRecords(let ids) = self {
                return ".linkedRecords(\(ids.map { $0?.rawValue ?? "nil" }.joined(separator: ", ")))"
            } else {
                preconditionFailure("Unexpected case of Value: \(self)")
            }
        }
    }

    public subscript(_ storageKey: String) -> Any? {
        get {
            if let value = fields[storageKey] {
                if let s = value.scalar {
                    return s
                } else {
                    preconditionFailure("Expected a scalar (non-link) value for key \(storageKey)")
                }
            } else {
                return nil
            }
        }
        set {
            if let val = newValue  {
                if let value = Value(scalar: val) {
                    fields[storageKey] = value
                } else {
                    preconditionFailure("Cannot convert type \(type(of: val)) into a scalar value")
                }
            } else {
                fields.removeValue(forKey: storageKey)
            }
        }
    }

    public func getLinkedRecordID(_ storageKey: String) -> DataID?? {
        if let value = fields[storageKey] {
            if case .null = value {
                return .some(nil)
            } else if case .linkedRecord(let dataID) = value {
                return dataID
            } else {
                preconditionFailure("Expected a linked record for key \(storageKey)")
            }
        } else {
            return nil
        }
    }

    public mutating func setLinkedRecordID(_ storageKey: String, _ id: DataID) {
        fields[storageKey] = .linkedRecord(id)
    }

    public func getLinkedRecordIDs(_ storageKey: String) -> [DataID?]?? {
        if let value = fields[storageKey] {
            if case .null = value {
                return .some(nil)
            } else if case .linkedRecords(let dataIDs) = value {
                return dataIDs
            } else {
                preconditionFailure("Expected an array of linked IDs for key \(storageKey)")
            }
        } else {
            return nil
        }
    }

    public mutating func setLinkedRecordIDs(_ storageKey: String, _ ids: [DataID?]) {
        fields[storageKey] = .linkedRecords(ids)
    }

    public mutating func copyFields(from source: Record) {
        for (k, v) in source.fields {
            fields[k] = v
        }
    }

    public mutating func update(from source: Record) {
        guard source.dataID == dataID else {
            preconditionFailure("Invalid record update, expected both versions of record to have the same ID, got \(source.dataID) and \(dataID)")
        }

        // TODO validate types are the same

        for (k, v) in source.fields {
            fields[k] = v
        }
    }
}

extension Record: CustomDebugStringConvertible {
    public var debugDescription: String {
        var s = "\(typename)[\(dataID.rawValue)] {\n"
        for (k, v) in fields {
            s += "  \(k): \(String(reflecting: v))\n"
        }
        s += "}"
        return s
    }
}

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

        if let linkedID = mutator.getLinkedRecordID(dataID: dataID, key: storageKey) {
            return source[linkedID]
        } else {
            return nil
        }
    }

    func getLinkedRecords(_ name: String, args: VariableDataConvertible?) -> [RecordProxy?]? {
        let storageKey = formatStorageKey(name: name, variables: args)

        if let linkedIDs = mutator.getLinkedRecordIDs(dataID: dataID, key: storageKey) {
            return linkedIDs.map { $0.flatMap { source[$0] } }
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
