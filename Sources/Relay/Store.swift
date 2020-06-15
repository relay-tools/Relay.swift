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
