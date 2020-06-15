public protocol RecordSourceProxy {
    mutating func create(dataID: DataID, typeName: String) -> RecordProxy
    mutating func delete(dataID: DataID)
    subscript(_ dataID: DataID) -> RecordProxy? { get }
    var root: RecordProxy { get }
    mutating func invalidateStore()
}

public class DefaultRecordSourceProxy: RecordSourceProxy {
    private let mutator: RecordSourceMutator
    private let handlerProvider: HandlerProvider?

    private var proxies: [DataID: RecordProxy?] = [:]
    private(set) var invalidatedStore = false
    private(set) var idsMarkedForInvalidation = Set<DataID>()

    init(mutator: RecordSourceMutator, handlerProvider: HandlerProvider? = nil) {
        self.mutator = mutator
        self.handlerProvider = handlerProvider
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

    func publish(source: RecordSource, fieldPayloads: [HandleFieldPayload] = []) {
        for dataID in source.recordIDs {
            switch source.getStatus(dataID) {
            case .existent:
                if let sourceRecord = source[dataID] {
                    if mutator.getStatus(dataID) != .existent {
                        _ = create(dataID: dataID, typeName: sourceRecord.typename)
                    }
                    mutator.copyFields(from: sourceRecord, to: dataID)
                }
            case .nonexistent:
                delete(dataID: dataID)
            case .unknown:
                break
            }
        }

        for fieldPayload in fieldPayloads {
            guard let handler = handlerProvider?.handler(for: fieldPayload.handle) else {
                preconditionFailure("Expected a handler to be provided for handle `\(fieldPayload.handle)`")
            }

            var this: RecordSourceProxy = self
            handler.update(store: &this, fieldPayload: fieldPayload)
        }
    }
}
