import Foundation
import Combine

public class SelectorDataDecoder: TopLevelDecoder {
    public func decode<T>(_ type: T.Type, from data: SelectorData) throws -> T where T : Decodable {
        let decoder = _SelectorDataDecoder(referencing: .value(.object(data)))
        return try decoder.decode(type)
    }
}

fileprivate class _SelectorDataDecoder: Decoder {
    var storage: _SelectorDataDecodingStorage
    fileprivate(set) public var codingPath: [CodingKey]
    public var userInfo: [CodingUserInfoKey : Any] { [:] }

    init(referencing container: _SelectorDataContainer?, at codingPath: [CodingKey] = []) {
        storage = _SelectorDataDecodingStorage()
        storage.push(container: container)
        self.codingPath = codingPath
    }

    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        guard let topContainer = storage.topContainer else {
            throw DecodingError.valueNotFound(
                KeyedDecodingContainer<Key>.self,
                DecodingError.Context(codingPath: codingPath,
                                      debugDescription: "Cannot get keyed decoding container, found nil value instead"))
        }

        guard case .value(.object(let data?)) = topContainer else {
            throw DecodingError.typeMismatch(
                SelectorData.self,
                DecodingError.Context(codingPath: codingPath,
                                      debugDescription: "Cannot get keyed decoding container, value \(topContainer) is not an object"))
        }

        let container = _SelectorDataKeyedDecodingContainer<Key>(referencing: self, wrapping: data)
        return KeyedDecodingContainer(container)
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        guard let topContainer = storage.topContainer else {
            throw DecodingError.valueNotFound(
                UnkeyedDecodingContainer.self,
                DecodingError.Context(codingPath: codingPath,
                                      debugDescription: "Cannot get unkeyed decoding container, found nil value instead"))
        }

        guard case .value(let value) = topContainer else {
            throw DecodingError.typeMismatch(
                [Any].self,
                DecodingError.Context(codingPath: codingPath,
                                      debugDescription: "Cannot get unkeyed decoding container, value \(topContainer) is a fragment pointer"))
        }

        switch value {
        case .array, .objects:
            return _SelectorDataUnkeyedDecodingContainer(referencing: self, wrapping: value)
        default:
            throw DecodingError.typeMismatch(
                [Any].self,
                DecodingError.Context(codingPath: codingPath,
                                      debugDescription: "Cannot get unkeyed decoding container, value \(topContainer) is not an array"))

        }
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        self
    }
}

fileprivate enum _SelectorDataContainer {
    case value(SelectorData.Value)
    case fragmentPointer(FragmentPointer)
}

fileprivate struct _SelectorDataDecodingStorage {
    private(set) var containers: [_SelectorDataContainer?] = []

    mutating func push(container: _SelectorDataContainer?) {
        containers.append(container)
    }

    mutating func popContainer() {
        precondition(!containers.isEmpty, "Empty container stack.")
        containers.removeLast()
    }

    var topContainer: _SelectorDataContainer? {
        precondition(!containers.isEmpty, "Empty container stack.")
        return containers.last!
    }
}

fileprivate struct _SelectorDataKeyedDecodingContainer<K : CodingKey> : KeyedDecodingContainerProtocol {
    typealias Key = K

    private let decoder: _SelectorDataDecoder
    private let container: SelectorData
    private(set) var codingPath: [CodingKey]

    init(referencing decoder: _SelectorDataDecoder, wrapping container: SelectorData) {
        self.decoder = decoder
        self.container = container
        self.codingPath = decoder.codingPath
    }

    var allKeys: [K] {
        (Array(container.data.keys) + container.fragments.keys).compactMap { Key(stringValue: $0) }
    }

    func contains(_ key: K) -> Bool {
        return container.data[key.stringValue] != nil || container.fragments[key.stringValue] != nil
    }

    private func _errorDescription(of key: CodingKey) -> String {
        return "\(key) (\"\(key.stringValue)\")"
    }

    public func decodeNil(forKey key: Key) throws -> Bool {
        if let entry = container.data[key.stringValue], entry != nil {
            return false
        }

        if container.fragments[key.stringValue] != nil {
            return false
        }

        return true
    }

    public func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
        guard let entry = container.data[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "No value associated with key \(_errorDescription(of: key))."))
        }

        decoder.codingPath.append(key)
        defer { decoder.codingPath.removeLast() }

        guard let value = try decoder.unbox(entry.map { .value($0) }, as: Bool.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        guard let entry = container.data[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "No value associated with key \(_errorDescription(of: key))."))
        }

        decoder.codingPath.append(key)
        defer { decoder.codingPath.removeLast() }

        guard let value = try decoder.unbox(entry.map { .value($0) }, as: Int.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        preconditionFailure("not supported")
    }

    public func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        preconditionFailure("not supported")
    }

    public func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        preconditionFailure("not supported")
    }

    public func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        preconditionFailure("not supported")
    }

    public func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        preconditionFailure("not supported")
    }

    public func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        preconditionFailure("not supported")
    }

    public func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        preconditionFailure("not supported")
    }

    public func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        preconditionFailure("not supported")
    }

    public func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        preconditionFailure("not supported")
    }

    public func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        preconditionFailure("not supported")
    }

    public func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        guard let entry = container.data[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "No value associated with key \(_errorDescription(of: key))."))
        }

        decoder.codingPath.append(key)
        defer { decoder.codingPath.removeLast() }

        guard let value = try decoder.unbox(entry.map { .value($0) }, as: Double.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: String.Type, forKey key: Key) throws -> String {
        guard let entry = container.data[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "No value associated with key \(_errorDescription(of: key))."))
        }

        decoder.codingPath.append(key)
        defer { decoder.codingPath.removeLast() }

        guard let value = try decoder.unbox(entry.map { .value($0) }, as: String.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode<T : Decodable>(_ type: T.Type, forKey key: Key) throws -> T {
        if type == FragmentPointer.self {
            guard key.stringValue.hasPrefix("fragment_") else {
                throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Fragment pointer key \(_errorDescription(of: key)) must begin with 'fragment_'."))
            }

            guard let entry = container.fragments[String(key.stringValue.dropFirst(9))] else {
                throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "No fragment pointer value associated with key \(_errorDescription(of: key))."))
            }

            decoder.codingPath.append(key)
            defer { decoder.codingPath.removeLast() }

            guard let value = try decoder.unbox(.fragmentPointer(entry), as: type) else {
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected fragment pointer but found null instead."))
            }

            return value
        }
        
        guard let entry = container.data[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(_errorDescription(of: key))."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry.map { .value($0) }, as: type) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> {
        decoder.codingPath.append(key)
        defer { decoder.codingPath.removeLast() }

        guard let value = container.data[key.stringValue] else {
            throw DecodingError.keyNotFound(
                key, DecodingError.Context(codingPath: self.codingPath,
                                           debugDescription: "Cannot get \(KeyedDecodingContainer<NestedKey>.self) -- no value found for key \(_errorDescription(of: key))"))
        }

        guard case .object(let data?)? = value else {
            throw DecodingError.typeMismatch(SelectorData.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot get KeyedDecodingContainer, value \(String(describing: value)) is not an object"))
        }

        let container = _SelectorDataKeyedDecodingContainer<NestedKey>(referencing: decoder, wrapping: data)
        return KeyedDecodingContainer(container)
    }

    public func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        decoder.codingPath.append(key)
        defer { decoder.codingPath.removeLast() }

        guard let value = container.data[key.stringValue] else {
            throw DecodingError.keyNotFound(
                key, DecodingError.Context(codingPath: codingPath,
                                           debugDescription: "Cannot get UnkeyedDecodingContainer -- no value found for key \(_errorDescription(of: key))"))
        }

        switch value {
        case .some(.array), .some(.objects):
            return _SelectorDataUnkeyedDecodingContainer(referencing: decoder, wrapping: value!)
        default:
            throw DecodingError.typeMismatch([Any].self, DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot get UnkeyedDecodingContainer, value \(String(describing: value)) is not an array"))
        }
    }

    private func _superDecoder(forKey key: CodingKey) throws -> Decoder {
        decoder.codingPath.append(key)
        defer { decoder.codingPath.removeLast() }

        let value = container.data[key.stringValue]!
        return _SelectorDataDecoder(referencing: value.map { _SelectorDataContainer.value($0) }, at: self.decoder.codingPath)
    }

    public func superDecoder() throws -> Decoder {
        fatalError()
    }

    public func superDecoder(forKey key: Key) throws -> Decoder {
        return try _superDecoder(forKey: key)
    }
}

fileprivate struct _SelectorDataUnkeyedDecodingContainer: UnkeyedDecodingContainer {
    private let decoder: _SelectorDataDecoder
    private let container: SelectorData.Value
    private(set) var codingPath: [CodingKey]
    private(set) var currentIndex: Int = 0

    init(referencing decoder: _SelectorDataDecoder, wrapping container: SelectorData.Value) {
        self.decoder = decoder
        self.container = container
        self.codingPath = decoder.codingPath
    }

    private var scalars: [SelectorData.Value?]? {
        if case .array(let values) = container {
            return values
        }
        return nil
    }

    private var objects: [SelectorData?]? {
        if case .objects(let values) = container {
            return values
        }
        return nil
    }

    public var count: Int? {
        switch container {
        case .array(let values):
            return values.count
        case .objects(let values):
            return values?.count ?? 0
        default:
            fatalError()
        }
    }

    public var isAtEnd: Bool {
        return self.currentIndex >= self.count!
    }

    public mutating func decodeNil() throws -> Bool {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(Any?.self, DecodingError.Context(codingPath: decoder.codingPath + [_SelectorDataKey(index: currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        switch container {
        case .array(let values):
            if values[currentIndex] == nil {
                currentIndex += 1
                return true
            } else {
                return false
            }
        case .objects(let values):
            if values![currentIndex] == nil {
                currentIndex += 1
                return true
            } else {
                return false
            }
        default:
            fatalError()
        }
    }

    public mutating func decode(_ type: Bool.Type) throws -> Bool {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath + [_SelectorDataKey(index: currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        decoder.codingPath.append(_SelectorDataKey(index: self.currentIndex))
        defer { decoder.codingPath.removeLast() }

        guard let values = scalars else {
            throw DecodingError.typeMismatch([Bool].self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected Bool array but found value \(container) instead"))
        }

        guard let decoded = try decoder.unbox(values[currentIndex].map { .value($0) }, as: Bool.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath + [_SelectorDataKey(index: currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: Int.Type) throws -> Int {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath + [_SelectorDataKey(index: currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        decoder.codingPath.append(_SelectorDataKey(index: self.currentIndex))
        defer { decoder.codingPath.removeLast() }

        guard let values = scalars else {
            throw DecodingError.typeMismatch([Int].self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected Int array but found value \(container) instead"))
        }

        guard let decoded = try decoder.unbox(values[currentIndex].map { .value($0) }, as: Int.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath + [_SelectorDataKey(index: currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: Int8.Type) throws -> Int8 {
        preconditionFailure("not supported")
    }

    public mutating func decode(_ type: Int16.Type) throws -> Int16 {
        preconditionFailure("not supported")
    }

    public mutating func decode(_ type: Int32.Type) throws -> Int32 {
        preconditionFailure("not supported")
    }

    public mutating func decode(_ type: Int64.Type) throws -> Int64 {
        preconditionFailure("not supported")
    }

    public mutating func decode(_ type: UInt.Type) throws -> UInt {
        preconditionFailure("not supported")
    }

    public mutating func decode(_ type: UInt8.Type) throws -> UInt8 {
        preconditionFailure("not supported")
    }

    public mutating func decode(_ type: UInt16.Type) throws -> UInt16 {
        preconditionFailure("not supported")
    }

    public mutating func decode(_ type: UInt32.Type) throws -> UInt32 {
        preconditionFailure("not supported")
    }

    public mutating func decode(_ type: UInt64.Type) throws -> UInt64 {
        preconditionFailure("not supported")
    }

    public mutating func decode(_ type: Float.Type) throws -> Float {
        preconditionFailure("not supported")
    }

    public mutating func decode(_ type: Double.Type) throws -> Double {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath + [_SelectorDataKey(index: currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        decoder.codingPath.append(_SelectorDataKey(index: self.currentIndex))
        defer { decoder.codingPath.removeLast() }

        guard let values = scalars else {
            throw DecodingError.typeMismatch([Double].self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected Double array but found value \(container) instead"))
        }

        guard let decoded = try decoder.unbox(values[currentIndex].map { .value($0) }, as: Double.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath + [_SelectorDataKey(index: currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: String.Type) throws -> String {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath + [_SelectorDataKey(index: currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        decoder.codingPath.append(_SelectorDataKey(index: self.currentIndex))
        defer { decoder.codingPath.removeLast() }

        guard let values = scalars else {
            throw DecodingError.typeMismatch([String].self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected String array but found value \(container) instead"))
        }

        guard let decoded = try decoder.unbox(values[currentIndex].map { .value($0) }, as: String.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath + [_SelectorDataKey(index: currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        currentIndex += 1
        return decoded
    }

    public mutating func decode<T : Decodable>(_ type: T.Type) throws -> T {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath + [_SelectorDataKey(index: currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        decoder.codingPath.append(_SelectorDataKey(index: self.currentIndex))
        defer { decoder.codingPath.removeLast() }

        guard let values = objects else {
            throw DecodingError.typeMismatch([T].self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected object array but found value \(container) instead"))
        }

        guard let decoded = try decoder.unbox(values[currentIndex].map { .value(.object($0)) }, as: type) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath + [_SelectorDataKey(index: currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        currentIndex += 1
        return decoded
    }

    public mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> {
        decoder.codingPath.append(_SelectorDataKey(index: self.currentIndex))
        defer { decoder.codingPath.removeLast() }

        guard !isAtEnd else {
            throw DecodingError.valueNotFound(KeyedDecodingContainer<NestedKey>.self,
                                              DecodingError.Context(codingPath: codingPath,
                                                                    debugDescription: "Cannot get nested keyed container -- unkeyed container is at end."))
        }

        guard let values = objects else {
            throw DecodingError.typeMismatch([SelectorData].self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected object array but found value \(container) instead"))
        }

        guard let value = values[self.currentIndex] else {
            throw DecodingError.valueNotFound(KeyedDecodingContainer<NestedKey>.self,
                                              DecodingError.Context(codingPath: codingPath,
                                                                    debugDescription: "Cannot get keyed decoding container -- found null value instead."))
        }

        currentIndex += 1
        let container = _SelectorDataKeyedDecodingContainer<NestedKey>(referencing: decoder, wrapping: value)
        return KeyedDecodingContainer(container)
    }

    public mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        // TODO I don't think our implementation of other things would correctly handle multi-dimensional arrays
        fatalError()
    }

    public mutating func superDecoder() throws -> Decoder {
        fatalError()
    }
}

extension _SelectorDataDecoder: SingleValueDecodingContainer {
    private func expectNonNull<T>(_ type: T.Type) throws {
        guard !self.decodeNil() else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Expected \(type) but found null value instead."))
        }
    }

    func decodeNil() -> Bool {
        return storage.topContainer == nil
    }

    func decode(_ type: Bool.Type) throws -> Bool {
        try expectNonNull(Bool.self)
        return try unbox(storage.topContainer, as: Bool.self)!
    }

    func decode(_ type: String.Type) throws -> String {
        try expectNonNull(String.self)
        return try unbox(storage.topContainer, as: String.self)!
    }

    func decode(_ type: Double.Type) throws -> Double {
        try expectNonNull(Double.self)
        return try unbox(storage.topContainer, as: Double.self)!
    }

    func decode(_ type: Float.Type) throws -> Float {
        preconditionFailure("not supported")
    }

    func decode(_ type: Int.Type) throws -> Int {
        try expectNonNull(String.self)
        return try unbox(storage.topContainer, as: Int.self)!
    }

    func decode(_ type: Int8.Type) throws -> Int8 {
        preconditionFailure("not supported")
    }

    func decode(_ type: Int16.Type) throws -> Int16 {
        preconditionFailure("not supported")
    }

    func decode(_ type: Int32.Type) throws -> Int32 {
        preconditionFailure("not supported")
    }

    func decode(_ type: Int64.Type) throws -> Int64 {
        preconditionFailure("not supported")
    }

    func decode(_ type: UInt.Type) throws -> UInt {
        preconditionFailure("not supported")
    }

    func decode(_ type: UInt8.Type) throws -> UInt8 {
        preconditionFailure("not supported")
    }

    func decode(_ type: UInt16.Type) throws -> UInt16 {
        preconditionFailure("not supported")
    }

    func decode(_ type: UInt32.Type) throws -> UInt32 {
        preconditionFailure("not supported")
    }

    func decode(_ type: UInt64.Type) throws -> UInt64 {
        preconditionFailure("not supported")
    }

    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        try expectNonNull(type)
        return try unbox(storage.topContainer, as: type)!
    }
}

fileprivate extension _SelectorDataDecoder {
    func unbox(_ value: _SelectorDataContainer?, as type: Bool.Type) throws -> Bool? {
        guard let value = value else { return nil }

        switch value {
        case .value(.bool(let v)):
            return v
        case .value(.int(let v)):
            return v != 0
        default:
            throw DecodingError.typeMismatch(Bool.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Expected to decode \(Bool.self) but found \(value) instead"))
        }
    }

    func unbox(_ value: _SelectorDataContainer?, as type: String.Type) throws -> String? {
        guard let value = value else { return nil }

        switch value {
        case .value(.string(let v)):
            return v
        default:
            throw DecodingError.typeMismatch(Bool.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Expected to decode \(String.self) but found \(value) instead"))
        }
    }

    func unbox(_ value: _SelectorDataContainer?, as type: Int.Type) throws -> Int? {
        guard let value = value else { return nil }

        switch value {
        case .value(.int(let v)):
            return v
        default:
            throw DecodingError.typeMismatch(Bool.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Expected to decode \(Int.self) but found \(value) instead"))
        }
    }

    func unbox(_ value: _SelectorDataContainer?, as type: Double.Type) throws -> Double? {
        guard let value = value else { return nil }

        switch value {
        case .value(.float(let v)):
            return v
        case .value(.int(let v)):
            return Double(v)
        default:
            throw DecodingError.typeMismatch(Bool.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Expected to decode \(Double.self) but found \(value) instead"))
        }
    }

    func unbox<T: Decodable>(_ value: _SelectorDataContainer?, as type: T.Type) throws -> T? {
        guard let value = value else { return nil }

        if type == FragmentPointer.self {
            guard case .fragmentPointer(let pointer) = value else {
                throw DecodingError.typeMismatch(FragmentPointer.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Expected to decoded a fragment pointer but found \(value) instead"))
            }

            return (pointer as! T)
        }

        if type == SelectorData.self {
            guard case .value(.object(let obj?)) = value else {
                throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Expected to decoded selector data but found \(value) instead"))
            }

            return (obj as! T)
        }

        storage.push(container: value)
        defer { storage.popContainer() }
        return try type.init(from: self)
    }
}

fileprivate struct _SelectorDataKey : CodingKey {
    public var stringValue: String
    public var intValue: Int?

    public init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    public init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }

    public init(stringValue: String, intValue: Int?) {
        self.stringValue = stringValue
        self.intValue = intValue
    }
    fileprivate init(index: Int) {
        self.stringValue = "Index \(index)"
        self.intValue = index
    }

    fileprivate static let `super` = _SelectorDataKey(stringValue: "super")!
}
