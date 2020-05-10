public class Store {
    private var recordSource: RecordSource

    private var currentWriteEpoch = 0
    private var updatedRecordIDs = Set<DataID>()
    private var invalidatedRecordIDs = Set<DataID>()
    private var subscriptions = [StoreSubscription]()

    public init(source: RecordSource) {
        recordSource = source

        initializeRecordSource()
    }

    public var source: RecordSource {
        get {
            recordSource
        }
        set {
            recordSource = newValue
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

    public func publish(source: RecordSource, idsMarkedForInvalidation: Set<DataID>? = nil) {
        self.source.update(from: source,
                           currentWriteEpoch: currentWriteEpoch + 1,
                           updatedRecordIDs: &updatedRecordIDs,
                           invalidatedRecordIDs: &invalidatedRecordIDs)
    }

    public func notify(sourceOperation: OperationDescriptor? = nil,
                       invalidateStore: Bool = false) -> [RequestDescriptor] {
        currentWriteEpoch += 1

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
            // track epoch at which operation was written to the store
        }

        return updatedOwners
    }

    public func subscribe<Data: Readable>(snapshot: Snapshot<Data?>) -> SnapshotPublisher<Data> {
        SnapshotPublisher(store: self, initialSnapshot: snapshot)
    }

    func subscribe(subscription: StoreSubscription) {
        subscriptions.append(subscription)
    }
    
    func unsubscribe(subscription: StoreSubscription) {
        subscriptions.removeAll(where: { $0 === subscription })
    }
}

protocol StoreSubscription: class {
    func storeUpdatedRecords(_ updatedIDs: Set<DataID>) -> RequestDescriptor?
}

public protocol Storable {
    var name: String { get }
    var storageKey: String? { get }
    var args: [Argument]? { get }
}

func getStorageKey<Vars: Variables>(field: Storable, variables: Vars) -> String {
    if let storageKey = field.storageKey {
        return storageKey
    }

    if let args = field.args, !args.isEmpty {
        return formatStorageKey(name: field.name, variables: getArgumentValues(args, variables))
    } else {
        return field.name
    }
}

func getArgumentValues<Vars: Variables>(_ args: [Argument], _ variables: Vars) -> [String: Any] {
    return Dictionary(uniqueKeysWithValues: args.map { ($0.name, getArgumentValue($0, variables)) })
}

private func getArgumentValue<Vars: Variables>(_ arg: Argument, _ variables: Vars) -> Any {
    if let arg = arg as? LiteralArgument {
        return arg.value
    } else if let arg = arg as? VariableArgument {
        return variables.asDictionary[arg.variableName]!
    } else if let arg = arg as? ObjectValueArgument {
        return Dictionary(uniqueKeysWithValues: arg.fields.map { ($0.name, getArgumentValue($0, variables)) })
    } else if let arg = arg as? ListValueArgument {
        return arg.items.map { item -> Any? in
            if let item = item {
                return getArgumentValue(item, variables)
            } else {
                return nil
            }
        }
    } else {
        preconditionFailure("Unexpected type of Argument: \(arg)")
    }
}

func formatStorageKey(name: String, variables: [String: Any]) -> String {
    if variables.isEmpty {
        return name
    }

    let varString = variables.keys.sorted().map { k in "\(k):\(variables[k]!)" }.joined(separator: ",")
    return "\(name)(\(varString))"
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
