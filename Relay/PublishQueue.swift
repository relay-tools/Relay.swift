public class PublishQueue {
    private let store: Store

    private var pendingData: [PendingCommit] = []

    init(store: Store) {
        self.store = store
    }

    enum PendingCommit {
        case payload(OperationDescriptor, ResponsePayload, Any?)
        case recordSource(RecordSource)
        // TODO updater
    }

    func commit(payload: ResponsePayload, operation: OperationDescriptor, updater: Any? = nil) {
        // TODO pending backup rebase
        pendingData.append(.payload(operation, payload, updater))
    }

    func run(sourceOperation: OperationDescriptor? = nil) -> [RequestDescriptor] {
        let invalidatedStore = commitData()
        
        // TODO optimistic updates
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
                invalidatedStore = invalidatedStore || publishStore(from: payload, operation: operation, updater: updater)
            case .recordSource(let source):
                store.publish(source: source)
            // TODO updater
            }
        }
        pendingData.removeAll()
        return invalidatedStore
    }

    private func publishStore(from payload: ResponsePayload, operation: OperationDescriptor, updater: Any?) -> Bool {
        // TODO stuff with field payloads and the updater
        store.publish(source: payload.source)
        return false
    }
}
