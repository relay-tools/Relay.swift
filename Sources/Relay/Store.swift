import Combine
import Foundation

public class Store {
    var recordSource: RecordSource
    var optimisticSource: RecordSource?

    private var updatedRecordIDs = Set<DataID>()
    private var invalidatedRecordIDs = Set<DataID>()
    private var subscriptions = [StoreSubscription]()
    private var gc: GarbageCollector!

    private var _currentWriteEpoch = 0
    private let _writeEpochLock = DispatchQueue(label: "relay-store-write-epoch-lock")

    var currentWriteEpoch: Int {
        _writeEpochLock.sync { _currentWriteEpoch }
    }

    public init(source: RecordSource = DefaultRecordSource()) {
        recordSource = source

        initializeRecordSource()
        gc = GarbageCollector(store: self)
    }

    public var source: RecordSource {
        get {
            if let source = optimisticSource {
                return source
            }
            return recordSource
        }
        set {
            if optimisticSource != nil {
                optimisticSource = newValue
            } else {
                recordSource = newValue
            }
        }
    }

    private func initializeRecordSource() {
        if !recordSource.has(.rootID) {
            recordSource[.rootID] = Record.root
        }
    }

    public func lookup<T: Readable>(selector: SingularReaderSelector) -> Snapshot<T?> {
        Reader.read(T.self, source: source, selector: selector)
    }

    public func retain(operation: OperationDescriptor) -> AnyCancellable {
        gc.retain(operation)
    }

    public func publish(source: RecordSource, idsMarkedForInvalidation: Set<DataID>? = nil) {
        self.source.update(from: source,
                           currentWriteEpoch: currentWriteEpoch + 1,
                           updatedRecordIDs: &updatedRecordIDs,
                           invalidatedRecordIDs: &invalidatedRecordIDs)
    }

    public func notify(sourceOperation: OperationDescriptor? = nil,
                       invalidateStore: Bool = false) -> [RequestDescriptor] {
        _writeEpochLock.sync {
            _currentWriteEpoch += 1
        }

        if invalidateStore {
            // TODO update invalidation epoch
        }

        var updatedOwners: [RequestDescriptor] = []
        for subscription in subscriptions {
            if let owner = subscription.storeUpdatedRecords(updatedRecordIDs) {
                updatedOwners.append(owner)
            }
        }
        // TODO invalidation subscriptions

        updatedRecordIDs.removeAll()
        invalidatedRecordIDs.removeAll()

        if let sourceOperation = sourceOperation {
            gc.updateEpoch(for: sourceOperation)
        }

        return updatedOwners
    }

    public func subscribe<Data: Readable>(snapshot: Snapshot<Data?>) -> SnapshotPublisher<Data> {
        SnapshotPublisher(store: self, initialSnapshot: snapshot)
    }

    public func snapshot() {
        precondition(optimisticSource == nil, "Unexpected call to snapshot() while a previous snapshot exists")

        for subscription in subscriptions {
            subscription.storeDidSnapshot(source: recordSource)
        }

        gc.invalidateCurrentRun()
        optimisticSource = OptimisticRecordSource(base: recordSource)
    }

    public func restore() {
        precondition(optimisticSource != nil, "Unexpected call to restore() without a snapshot")

        optimisticSource = nil
        gc.scheduleIfNeeded()

        for subscription in subscriptions {
            subscription.storeDidRestore()
        }
    }

    func pauseGarbageCollection() -> AnyCancellable {
        gc.pause()
    }

    func subscribe(subscription: StoreSubscription) {
        subscriptions.append(subscription)
    }
    
    func unsubscribe(subscription: StoreSubscription) {
        subscriptions.removeAll(where: { $0 === subscription })
    }
}

protocol StoreSubscription: class {
    func storeDidSnapshot(source: RecordSource)
    func storeDidRestore()
    func storeUpdatedRecords(_ updatedIDs: Set<DataID>) -> RequestDescriptor?
}

public protocol Storable {
    var name: String { get }
    var storageKey: String? { get }
    var args: [Argument]? { get }
}

func getStorageKey(field: Storable, variables: VariableData) -> String {
    if let storageKey = field.storageKey {
        return storageKey
    }

    if let args = field.args, !args.isEmpty {
        return formatStorageKey(name: field.name, variables: getArgumentValues(args, variables))
    } else {
        return field.name
    }
}

func getArgumentValues(_ args: [Argument], _ variables: VariableData) -> VariableData {
    return Dictionary(uniqueKeysWithValues: args.map { ($0.name, getArgumentValue($0, variables)) }).variableData
}

private func getArgumentValue(_ arg: Argument, _ variables: VariableData) -> VariableValue {
    if let arg = arg as? LiteralArgument {
        return arg.value.variableValue
    } else if let arg = arg as? VariableArgument {
        return variables[dynamicMember: arg.variableName]!
    } else if let arg = arg as? ObjectValueArgument {
        return Dictionary(uniqueKeysWithValues: arg.fields.map { ($0.name, getArgumentValue($0, variables)) }).variableValue
    } else if let arg = arg as? ListValueArgument {
        return arg.items.map { item -> VariableValue in
            if let item = item {
                return getArgumentValue(item, variables)
            } else {
                return .null
            }
        }.variableValue
    } else {
        preconditionFailure("Unexpected type of Argument: \(arg)")
    }
}

func formatStorageKey(name: String, variables: VariableDataConvertible?) -> String {
    guard let variables = variables else {
        return name
    }

    let variableData = variables.variableData
    if variableData.isEmpty {
        return name
    }

    return "\(name)(\(variableData.innerDescription))"
}

func getRelayHandleKey(
    handleName: String,
    key: String? = nil,
    fieldName: String? = nil
) -> String {
    if let key = key, !key.isEmpty {
        return "__\(key)_\(handleName)"
    }

    guard let fieldName = fieldName else {
        preconditionFailure("Expected handle to have either a key or a field name")
    }
    return "__\(fieldName)_\(handleName)"
}
