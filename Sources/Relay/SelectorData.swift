public struct SelectorData: Decodable, Equatable {
    private(set) var data: [String: Value?] = [:]
    private(set) var fragments: [String: FragmentPointer] = [:]

    public enum Value: Equatable {
        case int(Int)
        case float(Double)
        case string(String)
        case bool(Bool)
        case array([Value?])
        case object(SelectorData?)
        case objects([SelectorData?]?)

        init?(scalar: Any) {
            if let v = scalar as? Int {
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
            case .int(let v):
                return v
            case .float(let v):
                return v
            case .string(let v):
                return v
            case .bool(let v):
                return v
            case .array(let v):
                return v.map { $0?.scalar }
            case .object, .objects:
                return nil
            }
        }

        var debugDescription: String {
            if let v = scalar {
                return String(reflecting: v)
            } else if case .object(let data) = self {
                return String(reflecting: data)
            } else if case .objects(let data) = self {
                return String(reflecting: data)
            } else {
                preconditionFailure("Unexpected case of Value: \(self)")
            }
        }
    }

    init() {}

    public init(from data: SelectorData) {
        self = data
    }

    public init(from decoder: Decoder) throws {
        // this would be an infinite recursion if SelectorDataDecoder didn't special-case this
        self = try decoder.singleValueContainer().decode(SelectorData.self)
    }

    public func get<T: ReadableScalar>(_ type: T.Type, _ key: String) -> T {
        return T(from: data[key]!!)
    }

    public func get<T: ReadableScalar>(_ type: T?.Type, _ key: String) -> T? {
        guard let val = data[key], let val2 = val else { return nil }
        return T(from: val2)
    }

    public func get(_ type: SelectorData?.Type, _ key: String) -> SelectorData? {
        guard let val = data[key] else { return nil }

        if case .object(let obj) = val {
            return obj
        }

        preconditionFailure("Expected key \(key) to contain an object, instead it was \(String(describing: data[key]))")
    }

    public func get(_ type: [SelectorData?]?.Type, _ key: String) -> [SelectorData?]? {
        guard let val = data[key] else { return nil }

        if case .objects(let objs) = val {
            return objs
        }

        preconditionFailure("Expected key \(key) to contain an array of objects, instead it was \(String(describing: data[key]))")
    }

    public func get(fragment: String) -> FragmentPointer? {
        return fragments[fragment]
    }

    public func get(path: [Any]) -> Any? {
        var current: Value = .object(self)
        var newPath = path

        while !newPath.isEmpty {
            let nextKey = newPath.removeFirst()

            if let nextKey = nextKey as? String {
                guard case .object(let obj) = current else {
                    preconditionFailure("Expected an object when extracting value at path")
                }
                guard let value = obj?.data[nextKey], let value2 = value else {
                    return nil
                }

                current = value2
            } else if let nextIndex = nextKey as? Int {
                guard case .objects(let objs) = current else {
                    preconditionFailure("Expected an array when extracting value at path")
                }
                guard let objs2 = objs else {
                    return nil
                }

                current = .object(objs2[nextIndex])
            } else {
                preconditionFailure("Unexpected type of key in path: \(nextKey)")
            }
        }

        if case .object(let obj) = current {
            return obj
        } else if case .objects(let objs) = current {
            return objs
        } else {
            return current.scalar
        }
    }

    mutating func set(_ key: String, scalar: Any?) {
        if let val = scalar {
            if let value = Value(scalar: val) {
                data[key] = value
            } else {
                preconditionFailure("Cannot convert type \(type(of: val)) into a scalar value")
            }
        } else {
            data.removeValue(forKey: key)
        }
    }

    mutating func set(_ key: String, object: SelectorData?) {
        data[key] = .object(object)
    }

    mutating func set(_ key: String, objects: [SelectorData?]?) {
        data[key] = .objects(objects)
    }

    mutating func set(fragment: String, variables: VariableData, dataID: DataID, owner: RequestDescriptor) {
        fragments[fragment] = FragmentPointer(variables: variables, id: dataID, owner: owner)
    }
}
