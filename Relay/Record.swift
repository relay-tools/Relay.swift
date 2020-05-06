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
        case int(Int)
        case float(Double)
        case string(String)
        case bool(Bool)
        case linkedRecord(DataID)
        case linkedRecords([DataID?])

        init?(scalar: Any) {
            if let v = scalar as? Int {
                self = .int(v)
            } else if let v = scalar as? Double {
                self = .float(v)
            } else if let v = scalar as? String {
                self = .string(v)
            } else if let v = scalar as? Bool {
                self = .bool(v)
            } else {
                return nil
            }
        }

        var scalar: Any? {
            switch self {
            case .int(let v):
                return v
            case .float(let v):
                return v
            case .string(let v):
                return v
            case .bool(let v):
                return v
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
            if let val = newValue {
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

    public func getLinkedRecordID(_ storageKey: String) -> DataID? {
        if let value = fields[storageKey] {
            if case .linkedRecord(let dataID) = value {
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

    public func getLinkedRecordIDs(_ storageKey: String) -> [DataID?]? {
        if let value = fields[storageKey] {
            if case .linkedRecords(let dataIDs) = value {
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


//public struct RootRecord: Record {
//    public var dataID: DataID = .rootID
//    public var typename = "__Root"
//}
