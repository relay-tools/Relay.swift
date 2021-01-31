import Foundation

let viewerType = "Viewer"

public struct Record: Equatable {
    public static let root = Record(dataID: .rootID, typename: "__Root")

    public var dataID: DataID
    public var typename: String

    public private(set) var fields: [String: Value] = [:]

    public internal(set) var invalidatedAt: Int?

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

    public enum Value: Equatable, CustomDebugStringConvertible {
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

        public var debugDescription: String {
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
            if storageKey == "__id" {
                return dataID.rawValue
            }

            if let value = fields[storageKey] {
                if let s = value.scalar {
                    return s
                } else {
                    preconditionFailure("Expected a scalar (non-link) value for key \(storageKey)")
                }
            } else if storageKey == "__typename" {
                return typename
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

extension Record: Codable {
}

extension Record.Value: Codable {
    enum CodingKeys: String, CodingKey {
        case type = "__type"
        case value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "null":
            self = .null
        case "int":
            self = .int(try container.decode(Int.self, forKey: .value))
        case "float":
            self = .float(try container.decode(Double.self, forKey: .value))
        case "string":
            self = .string(try container.decode(String.self, forKey: .value))
        case "bool":
            self = .bool(try container.decode(Bool.self, forKey: .value))
        case "array":
            self = .array(try container.decode([Record.Value?].self, forKey: .value))
        case "linkedRecord":
            self = .linkedRecord(try container.decode(DataID.self, forKey: .value))
        case "linkedRecords":
            self = .linkedRecords(try container.decode([DataID?].self, forKey: .value))
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unexpected type \"\(type)\" in record value")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .null:
            try container.encode("null", forKey: .type)
        case .int(let v):
            try container.encode("int", forKey: .type)
            try container.encode(v, forKey: .value)
        case .float(let v):
            try container.encode("float", forKey: .type)
            try container.encode(v, forKey: .value)
        case .string(let v):
            try container.encode("string", forKey: .type)
            try container.encode(v, forKey: .value)
        case .bool(let v):
            try container.encode("bool", forKey: .type)
            try container.encode(v, forKey: .value)
        case .array(let v):
            try container.encode("array", forKey: .type)
            try container.encode(v, forKey: .value)
        case .linkedRecord(let v):
            try container.encode("linkedRecord", forKey: .type)
            try container.encode(v, forKey: .value)
        case .linkedRecords(let v):
            try container.encode("linkedRecords", forKey: .type)
            try container.encode(v, forKey: .value)
        }
    }
}
