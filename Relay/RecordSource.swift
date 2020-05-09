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

public protocol RecordSourceProxy {
    mutating func create(dataID: DataID, typeName: String) -> RecordProxy
    mutating func delete(dataID: DataID)
    subscript(_ dataID: DataID) -> RecordProxy? { get }
    var root: RecordProxy { get }
    mutating func invalidateStore()
}

public protocol RecordSourceSelectorProxy: RecordSourceProxy {
    func getRootField(_ fieldName: String) -> RecordProxy?
    func getPluralRootField(_ fieldName: String) -> [RecordProxy?]?
}

public class DefaultRecordSourceProxy: RecordSourceProxy {
    private let mutator: RecordSourceMutator
    private var proxies: [DataID: RecordProxy?] = [:]
    private(set) var invalidatedStore = false
    private(set) var idsMarkedForInvalidation = Set<DataID>()

    init(mutator: RecordSourceMutator) {
        self.mutator = mutator
    }

    public func create(dataID: DataID, typeName: String) -> RecordProxy {
        mutator.create(dataID: dataID, typeName: typeName)
        proxies[dataID] = nil
        return self[dataID]!
    }

    public func delete(dataID: DataID) {
        proxies[dataID] = nil
        mutator.delete(dataID: dataID)
    }

    public subscript(dataID: DataID) -> RecordProxy? {
        if proxies[dataID] == nil {
            switch mutator.getStatus(dataID) {
            case .existent:
                proxies[dataID] = DefaultRecordProxy(source: self, mutator: mutator, dataID: dataID)
            case .nonexistent:
                proxies[dataID] = .some(nil)
            case .unknown:
                proxies[dataID] = nil
            }
        }
        return proxies[dataID].flatMap { $0 }
    }

    public var root: RecordProxy {
        var root = self[.rootID]
        if root == nil {
            root = create(dataID: .rootID, typeName: Record.root.typename)
        }

        guard let theRoot = root, theRoot.typeName == Record.root.typename else {
            preconditionFailure("Expected the source to contain a valid root record")
        }

        return theRoot
    }

    public func invalidateStore() {
        invalidatedStore = true
    }

    func markIDForInvalidation(_ dataID: DataID) {
        idsMarkedForInvalidation.insert(dataID)
    }
}
