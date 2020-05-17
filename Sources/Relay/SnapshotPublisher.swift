import Combine

public struct SnapshotPublisher<Data: Readable>: Publisher {
    public typealias Output = Snapshot<Data?>
    public typealias Failure = Never

    let store: Store
    let initialSnapshot: Output

    init(store: Store, initialSnapshot: Output) {
        self.store = store
        self.initialSnapshot = initialSnapshot
    }

    public func receive<S>(subscriber: S) where S: Subscriber, Self.Failure == S.Failure, Self.Output == S.Input {
        let inner = Inner(downstream: subscriber, store: store, snapshot: initialSnapshot)
        subscriber.receive(subscription: inner)
    }

    final class Inner<Downstream: Subscriber>: Subscription, StoreSubscription where Downstream.Input == Output, Downstream.Failure == Failure {
        private let downstream: Downstream
        private let recordStore: Relay.Store

        var snapshot: Output
        var backup: Output?
        var stale = false

        var hasPendingUpdates = false
        var demand: Subscribers.Demand = .none

        init(downstream: Downstream, store: Relay.Store, snapshot: Output) {
            self.downstream = downstream
            self.recordStore = store
            self.snapshot = snapshot

            store.subscribe(subscription: self)
        }

        func storeDidSnapshot(source: RecordSource) {
            if !stale {
                backup = snapshot
            } else {
                backup = Reader.read(Data.self, source: source, selector: snapshot.selector)
            }
        }

        func storeDidRestore() {
            if let backup = backup {
                if backup != snapshot {
                    stale = true
                }

                snapshot.isMissingData = backup.isMissingData
                snapshot.seenRecords = backup.seenRecords
                snapshot.selector = backup.selector
            } else {
                stale = true
            }

            backup = nil
        }

        func storeUpdatedRecords(_ updatedIDs: Set<DataID>) -> RequestDescriptor? {
            let hasNewUpdates = !updatedIDs.intersection(snapshot.seenRecords.keys).isEmpty
            let owner = hasNewUpdates ? snapshot.selector.owner : nil

            hasPendingUpdates = hasPendingUpdates || hasNewUpdates
            fulfillDemand()

            return owner
        }

        func request(_ demand: Subscribers.Demand) {
            self.demand += demand
            fulfillDemand()
        }

        private func fulfillDemand() {
            if demand > 0 && (hasPendingUpdates || stale) {
                let newSnapshot: Snapshot<Data?> =
                    hasPendingUpdates || backup == nil
                        ? recordStore.lookup(selector: snapshot.selector)
                        : backup!
                hasPendingUpdates = false
                stale = false

                if newSnapshot == snapshot {
                    return
                }

                snapshot = newSnapshot
                let newDemand = downstream.receive(snapshot)

                demand += newDemand
                demand -= 1
            }
        }

        func cancel() {
            recordStore.unsubscribe(subscription: self)
        }
    }
}
