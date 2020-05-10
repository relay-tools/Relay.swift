public class PublishQueue {
    private let store: Store
    private let handlerProvider: HandlerProvider

    private var pendingData: [PendingCommit] = []

    init(store: Store, handlerProvider: HandlerProvider) {
        self.store = store
        self.handlerProvider = handlerProvider
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
}
