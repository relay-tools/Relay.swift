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
        var hasPendingUpdates = false
        var demand: Subscribers.Demand = .none

        init(downstream: Downstream, store: Relay.Store, snapshot: Output) {
            self.downstream = downstream
            self.recordStore = store
            self.snapshot = snapshot

            store.subscribe(subscription: self)
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
            if demand > 0 && hasPendingUpdates {
                snapshot = recordStore.lookup(selector: snapshot.selector)
                let newDemand = downstream.receive(snapshot)
                hasPendingUpdates = false

                demand += newDemand
                demand -= 1
            }
        }

        func cancel() {
            recordStore.unsubscribe(subscription: self)
        }
    }
}
