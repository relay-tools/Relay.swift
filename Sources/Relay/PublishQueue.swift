public class PublishQueue {
    private let store: Store
    private let handlerProvider: HandlerProvider

    private var hasStoreSnapshot = false
    private var pendingData: [PendingCommit] = []
    private var pendingOptimisticUpdates = Set<OptimisticUpdate>()
    private var appliedOptimisticUpdates = Set<OptimisticUpdate>()
    private var pendingBackupRebase = false

    init(store: Store, handlerProvider: HandlerProvider) {
        self.store = store
        self.handlerProvider = handlerProvider
    }

    enum PendingCommit {
        case payload(OperationDescriptor, ResponsePayload, Any?)
        case recordSource(RecordSource)
        // TODO updater
    }

    func apply(_ update: OptimisticUpdate) {
        precondition(!appliedOptimisticUpdates.contains(update) && !pendingOptimisticUpdates.contains(update),
                     "Cannot apply the same update function more than once concurrently")
        pendingOptimisticUpdates.insert(update)
    }

    func revert(_ update: OptimisticUpdate) {
        if pendingOptimisticUpdates.contains(update) {
            pendingOptimisticUpdates.remove(update)
        } else if appliedOptimisticUpdates.contains(update) {
            pendingBackupRebase = true
            appliedOptimisticUpdates.remove(update)
        }
    }

    func commit(payload: ResponsePayload, operation: OperationDescriptor, updater: Any? = nil) {
        pendingBackupRebase = true
        pendingData.append(.payload(operation, payload, updater))
    }

    func run(sourceOperation: OperationDescriptor? = nil) -> [RequestDescriptor] {
        if pendingBackupRebase {
            restoreStoreIfNeeded()
        }

        let invalidatedStore = commitData()
        
        if !pendingOptimisticUpdates.isEmpty || (pendingBackupRebase && !appliedOptimisticUpdates.isEmpty) {
            snapshotStoreIfNeeded()
            applyUpdates()
        }

        pendingBackupRebase = false
        // TODO hold gc
        
        return store.notify(sourceOperation: sourceOperation, invalidateStore: invalidatedStore)
    }

    private func commitData() -> Bool {
        if pendingData.isEmpty {
            return false
        }

        var invalidatedStore = false
        for data in pendingData {
            switch data {
            case .payload(let operation, let payload, let updater):
                invalidatedStore = invalidatedStore || publishSource(from: payload, operation: operation, updater: updater)
            case .recordSource(let source):
                store.publish(source: source)
            // TODO updater
            }
        }
        pendingData.removeAll()
        return invalidatedStore
    }

    private func publishSource(from payload: ResponsePayload, operation: OperationDescriptor, updater: Any?) -> Bool {
        let mutator = RecordSourceMutator(base: store.source, sink: payload.source)
        var recordSourceProxy: RecordSourceProxy = DefaultRecordSourceProxy(mutator: mutator)

        for fieldPayload in payload.fieldPayloads {
            guard let handler = handlerProvider.handler(for: fieldPayload.handle) else {
                preconditionFailure("Expected a handler to be provided for handle '\(fieldPayload.handle)'")
            }

            handler.update(store: &recordSourceProxy, fieldPayload: fieldPayload)
        }

        // TODO stuff with the updater
        store.publish(source: mutator.sink)
        return (recordSourceProxy as! DefaultRecordSourceProxy).invalidatedStore
    }

    private func applyUpdates() {
        let mutator = RecordSourceMutator(base: store.source, sink: DefaultRecordSource())
        var defaultRecordSourceProxy = DefaultRecordSourceProxy(mutator: mutator, handlerProvider: handlerProvider)
        var recordSourceProxy = defaultRecordSourceProxy as RecordSourceProxy

        func processUpdate(_ update: OptimisticUpdate) {
            // TODO store updater if that's a thing we do

            let recordSourceSelectorProxy = DefaultRecordSourceSelectorProxy(
                mutator: mutator,
                recordSource: recordSourceProxy,
                readSelector: update.operation.fragment
            )

            defaultRecordSourceProxy.publish(source: update.payload.source, fieldPayloads: update.payload.fieldPayloads)
            let selectorData = Reader.read(SelectorData.self, source: update.payload.source, selector: update.operation.fragment).data

            if let updater = update.updater {
                updater(recordSourceSelectorProxy, selectorData)
            }
        }

        if !pendingOptimisticUpdates.isEmpty {
            for update in pendingOptimisticUpdates {
                processUpdate(update)
                appliedOptimisticUpdates.insert(update)
            }
            pendingOptimisticUpdates.removeAll()
        }

        store.publish(source: mutator.sink)
    }

    private func snapshotStoreIfNeeded() {
        if !hasStoreSnapshot {
            store.snapshot()
            hasStoreSnapshot = true
        }
    }

    private func restoreStoreIfNeeded() {
        if hasStoreSnapshot {
            store.restore()
            hasStoreSnapshot = false
        }
    }
}
