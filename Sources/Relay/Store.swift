import Combine
import Foundation
import os

private let logger = Logger(subsystem: "io.github.mjm.Relay", category: "store")

/// A container for cached query data.
///
/// Each Relay ``Environment`` has a store that contains records representing the data that has been fetched from the server using queries.
public class Store {
    var recordSource: RecordSource
    var optimisticSource: RecordSource?

    private var updatedRecordIDs = Set<DataID>()
    private var invalidatedRecordIDs = Set<DataID>()
    private var subscriptions = [StoreSubscription]()
    private var gc: GarbageCollector!

    private var _currentWriteEpoch = 0
    private let writeEpochLock = DispatchQueue(label: "relay-store-write-epoch-lock")
    private var globalInvalidationEpoch: Int?

    var currentWriteEpoch: Int {
        writeEpochLock.sync { _currentWriteEpoch }
    }

    /// Create a new store.
    ///
    /// You can create a new store by providing a record source. Usually the default empty record source is fine, but you could pass in a pre-populated one if you were loading records from an on-disk cache, for instance. You'll usually create a store as part of creating your app's ``Environment``.
    ///
    /// - Parameters:
    ///   - source: The initial records that the store is populated with. By default, the store starts with an empty record source.
    ///   - gcScheduler: The queue to use when performing garbage collection. By default, Relay creates a new serial queue for garbage collection of records.
    public init(
        source: RecordSource = DefaultRecordSource(),
        gcReleaseBufferSize: Int = 0,
        gcScheduler: DispatchQueue = DispatchQueue(label: "relay-garbage-collector")
    ) {
        recordSource = source

        initializeRecordSource()
        gc = GarbageCollector(
            store: self,
            releaseBufferSize: gcReleaseBufferSize,
            scheduler: gcScheduler
        )
    }

    /// The source of records currently being used by the store.
    ///
    /// The store may be managing one or two record sources depending on the state of your application. Most of the time,
    /// there is a single record source that is updated as new queries return data. While a mutation is in-flight that is using
    /// optimistic updates, the store keeps track of a second record source that contains the optimistically updated records.
    /// This property gets and sets that optimistic record source if it exists, or the normal one otherwise.
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

    public func lookup<T: Decodable>(selector: SingularReaderSelector) -> Snapshot<T?> {
        Reader.read(T.self, source: source, selector: selector)
    }

    public func retain(operation: OperationDescriptor) -> AnyCancellable {
        gc.retain(operation)
    }

    public func check(operation: OperationDescriptor) -> OperationAvailability {
        let selector = operation.root
        let rootEntry = gc.roots[operation.request.identifier]
        let lastWrittenAt = rootEntry?.epoch

        if let globalInvalidationEpoch = globalInvalidationEpoch {
            guard let lastWrittenAt = lastWrittenAt,
                  lastWrittenAt > globalInvalidationEpoch else {
                return .stale
            }
        }

        let operationAvailability = DataChecker.check(source: source, selector: selector)

        if let mostRecentlyInvalidatedAt = operationAvailability.mostRecentlyInvalidatedAt {
            if let lastWrittenAt = lastWrittenAt, mostRecentlyInvalidatedAt > lastWrittenAt {
                return .stale
            }
        }

        if case .missing = operationAvailability {
            return .missing
        }

        return .available(rootEntry?.fetchTime)
    }

    public func publish(source: RecordSource, idsMarkedForInvalidation: Set<DataID> = []) {
        self.source.update(from: source,
                           currentWriteEpoch: currentWriteEpoch + 1,
                           idsMarkedForInvalidation: idsMarkedForInvalidation,
                           updatedRecordIDs: &updatedRecordIDs,
                           invalidatedRecordIDs: &invalidatedRecordIDs)

        if optimisticSource != nil {
            logger.debug("Publish: \(source.count) records (optimistic)")
        } else {
            logger.debug("Publish: \(source.count) records")
        }
    }

    public func notify(
        sourceOperation: OperationDescriptor? = nil,
        invalidateStore: Bool = false
    ) -> [RequestDescriptor] {
        writeEpochLock.sync {
            let newWriteEpoch = _currentWriteEpoch + 1
            _currentWriteEpoch = newWriteEpoch

            if invalidateStore {
                globalInvalidationEpoch = newWriteEpoch
            }

            if let op = sourceOperation {
                logger.debug("Notify: \(op.request.node.params.name, privacy: .public)\(op.request.variables) [\(newWriteEpoch)]")
            }
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

    public func subscribe<Data: Decodable>(snapshot: Snapshot<Data?>) -> SnapshotPublisher<Data> {
        SnapshotPublisher(store: self, initialSnapshot: snapshot)
    }

    public func snapshot() {
        precondition(optimisticSource == nil, "Unexpected call to snapshot() while a previous snapshot exists")

        logger.debug("Snapshot")

        for subscription in subscriptions {
            subscription.storeDidSnapshot(source: recordSource)
        }

        gc.invalidateCurrentRun()
        optimisticSource = OptimisticRecordSource(base: recordSource)
    }

    public func restore() {
        precondition(optimisticSource != nil, "Unexpected call to restore() without a snapshot")

        logger.debug("Restore")

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

protocol StoreSubscription: AnyObject {
    func storeDidSnapshot(source: RecordSource)
    func storeDidRestore()
    func storeUpdatedRecords(_ updatedIDs: Set<DataID>) -> RequestDescriptor?
}
