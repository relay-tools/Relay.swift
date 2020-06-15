import Foundation

struct OptimisticUpdate: Hashable {
    let id: UUID

    var operation: OperationDescriptor
    var payload: ResponsePayload
    var updater: SelectorStoreUpdater?

    init(operation: OperationDescriptor, payload: ResponsePayload, updater: SelectorStoreUpdater?) {
        self.id = UUID()
        self.operation = operation
        self.payload = payload
        self.updater = updater
    }

    static func ==(lhs: OptimisticUpdate, rhs: OptimisticUpdate) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
