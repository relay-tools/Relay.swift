public class Store {
    private var recordSource: RecordSource

    private var currentWriteEpoch = 0
    private var updatedRecordIDs = Set<DataID>()
    private var invalidatedRecordIDs = Set<DataID>()

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

    public func publish(source: RecordSource, idsMarkedForInvalidation: Set<DataID>? = nil) {
        self.source.update(from: source,
                           currentWriteEpoch: currentWriteEpoch + 1,
                           updatedRecordIDs: &updatedRecordIDs,
                           invalidatedRecordIDs: &invalidatedRecordIDs)
    }

    public func notify(sourceOperation: OperationDescriptor? = nil,
                       invalidateStore: Bool = false) -> [RequestDescriptor] {
        currentWriteEpoch += 1

        // TODO invalidate store

        var updatedOwners: [RequestDescriptor] = []
        // TODO update subscriptions

        updatedRecordIDs.removeAll()
        invalidatedRecordIDs.removeAll()

        if let sourceOperation = sourceOperation {
            // track epoch at which operation was written to the store
        }

        return updatedOwners
    }
}

public protocol Storable {
    var name: String { get }
    var storageKey: String? { get }
    var args: [Argument]? { get }
}

func getStorageKey<Vars: Encodable>(field: Storable, variables: Vars) -> String {
    if let storageKey = field.storageKey {
        return storageKey
    }

    if let args = field.args, !args.isEmpty {
        return formatStorageKey(name: field.name, variables: getArgumentValues(args, variables))
    } else {
        return field.name
    }
}

func getArgumentValues<Vars>(_ args: [Argument], _ variables: Vars) -> [(String, Any)] {
    return args.map { ($0.name, getArgumentValue($0, variables)) }
}

private func getArgumentValue<Vars>(_ arg: Argument, _ variables: Vars) -> Any {
    if let arg = arg as? LiteralArgument {
        return arg.value
    } else if let arg = arg as? VariableArgument {
        return Mirror(reflecting: variables).descendant(arg.variableName)!
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

private func formatStorageKey(name: String, variables: [(String, Any)]) -> String {
    if variables.isEmpty {
        return name
    }

    let varString = variables.map { (k, v) in "\(k):\(v)" }.joined(separator: ",")
    return "\(name)(\(varString))"
}
