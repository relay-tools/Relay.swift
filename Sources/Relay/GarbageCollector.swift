import Combine
import Foundation
import os

private let log = OSLog(subsystem: "io.github.mjm.Relay", category: "garbage-collection")

@available(iOS 14.0, *)
private let logger = Logger(log)

class GarbageCollector {
    let store: Store
    let gcReleaseBufferSize: Int

    private let scheduler: DispatchQueue
    private var shouldSchedule = false
    private var isRunning = false
    private var holdCounter = 0
    private var roots: [String: Entry] = [:]
    private var releaseBuffer: [String] = []

    init(store: Store, gcReleaseBufferSize: Int = 0) {
        self.store = store
        self.gcReleaseBufferSize = gcReleaseBufferSize
        self.scheduler = DispatchQueue(label: "relay-garbage-collector")
    }

    struct Entry {
        var operation: OperationDescriptor
        var refCount: Int = 1
        var epoch: Int?
        var fetchTime: Date?
    }

    func retain(_ operation: OperationDescriptor) -> AnyCancellable {
        let id = operation.request.identifier
        let signpostID = OSSignpostID(log: log)

        var isCancelled = false
        let cancel = AnyCancellable {
            if isCancelled {
                return
            }
            isCancelled = true

            guard self.roots[id] != nil else {
                return
            }

            if #available(iOS 14.0, *) {
                logger.info("GC Release: \(operation.request.node.params.name, privacy: .public), variables: \(operation.request.variables)")
            }
            os_signpost(.event, log: log, name: "release operation", signpostID: signpostID)
            self.roots[id]?.refCount -= 1

            // TODO query cache expiration time
            self.releaseBuffer.append(id)
            if self.releaseBuffer.count > self.gcReleaseBufferSize {
                self.roots.removeValue(forKey: self.releaseBuffer.removeFirst())
                self.schedule()
            }
        }

        if #available(iOS 14.0, *) {
            logger.info("GC Retain:  \(operation.request.node.params.name, privacy: .public), variables: \(operation.request.variables)")
        }
        os_signpost(.event, log: log, name: "retain operation", signpostID: signpostID)

        guard let rootEntry = roots[id] else {
            roots[id] = Entry(operation: operation)
            return cancel
        }

        if rootEntry.refCount == 0 {
            releaseBuffer.removeAll { $0 == id }
        }

        roots[id]?.refCount += 1

        return cancel
    }

    func updateEpoch(for operation: OperationDescriptor) {
        let id = operation.request.identifier

        if var rootEntry = roots[id] {
            rootEntry.epoch = store.currentWriteEpoch
            rootEntry.fetchTime = Date()
            roots[id] = rootEntry
            return
        }

        if operation.request.node.params.operationKind == .query && gcReleaseBufferSize > 0 && releaseBuffer.count < gcReleaseBufferSize {
            releaseBuffer.append(id)
            roots[id] = Entry(operation: operation, refCount: 0, epoch: store.currentWriteEpoch, fetchTime: Date())
        }
    }

    func pause() -> AnyCancellable {
        if isRunning {
            shouldSchedule = true
        }
        holdCounter += 1

        if #available(iOS 14.0, *) {
            let holdCounter = self.holdCounter
            logger.info("GC Pause   (hold counter: \(holdCounter)")
        }
        os_signpost(.event, log: log, name: "pause")

        return AnyCancellable {
            if self.holdCounter > 0 {
                self.holdCounter -= 1

                if #available(iOS 14.0, *) {
                    let holdCounter = self.holdCounter
                    logger.info("GC Unpause (hold counter: \(holdCounter)")
                }
                os_signpost(.event, log: log, name: "unpause")

                if self.holdCounter == 0 && self.shouldSchedule {
                    self.schedule()
                    self.shouldSchedule = false
                }
            } else {
                if #available(iOS 14.0, *) {
                    logger.error("GC Unpause when hold counter is already 0")
                }
            }
        }
    }

    func invalidateCurrentRun() {
        if isRunning {
            shouldSchedule = true
        }
    }

    func scheduleIfNeeded() {
        if shouldSchedule {
            schedule()
        }
    }

    private func schedule() {
        guard holdCounter == 0 else {
            shouldSchedule = true
            return
        }

        guard !isRunning else {
            return
        }

        if #available(iOS 14.0, *) {
            logger.notice("GC Schedule")
        }
        let id = OSSignpostID(log: log)
        os_signpost(.event, log: log, name: "schedule", signpostID: id)

        isRunning = true
        scheduler.async {
            self.collect(id)
        }
    }

    private func collect(_ signpostID: OSSignpostID) {
        os_signpost(.begin, log: log, name: "garbage collection", signpostID: signpostID)
        while !attemptCollection(signpostID) { }
        isRunning = false
        os_signpost(.end, log: log, name: "garbage collection", signpostID: signpostID)
    }

    private func attemptCollection(_ signpostID: OSSignpostID) -> Bool {
        let startEpoch = store.currentWriteEpoch
        var references = Set<DataID>()

        for rootEntry in roots.values {
            let selector = rootEntry.operation.root

            ReferenceMarker.mark(
                source: store.recordSource,
                selector: selector,
                references: &references)

            let currentEpoch = store.currentWriteEpoch
            if startEpoch != currentEpoch {
                if #available(iOS 14.0, *) {
                    logger.info("GC Restart: store updated while collecting (start epoch: \(startEpoch), current epoch: \(currentEpoch))")
                }
                os_signpost(.event, log: log, name: "restart garbage collection", signpostID: signpostID)
                return false
            }

            if shouldSchedule {
                if #available(iOS 14.0, *) {
                    logger.info("GC Cancel: paused while collecting")
                }
                os_signpost(.event, log: log, name: "cancel garbage collection", signpostID: signpostID)
                return true
            }
        }

        // hop back onto the main queue while we update the store
        return DispatchQueue.main.sync {
            // check this again now that we're on the main queue.
            // after this, nothing should be able to interrupt us, because updates
            // to the store should all happen on the main queue.
            let currentEpoch = store.currentWriteEpoch
            if startEpoch != currentEpoch {
                if #available(iOS 14.0, *) {
                    logger.info("GC Restart: store updated while collecting (start epoch: \(startEpoch), current epoch: \(currentEpoch))")
                }
                os_signpost(.event, log: log, name: "restart garbage collection", signpostID: signpostID)
                return false
            }

            if shouldSchedule {
                if #available(iOS 14.0, *) {
                    logger.info("GC Cancel: paused while collecting")
                }
                os_signpost(.event, log: log, name: "cancel garbage collection", signpostID: signpostID)
                return true
            }

            if references.isEmpty {
                store.recordSource.clear()
                if #available(iOS 14.0, *) {
                    logger.notice("GC Result:  0 references found, cleared entire store")
                }
            } else {
                var deletedCount = 0
                for dataID in store.recordSource.recordIDs {
                    if !references.contains(dataID) {
                        store.recordSource.remove(dataID)
                        deletedCount += 1
                    }
                }
                if #available(iOS 14.0, *) {
                    logger.notice("GC Result:  \(references.count) references found, deleted \(deletedCount) records")
                }
            }

            return true
        }
    }
}

fileprivate class ReferenceMarker {
    var source: RecordSource
    var variables: VariableData
    var references: Set<DataID>

    init(source: RecordSource, variables: VariableData, references: Set<DataID>) {
        self.source = source
        self.variables = variables
        self.references = references
    }

    static func mark(source: RecordSource, selector: NormalizationSelector, references: inout Set<DataID>) {
        let marker = ReferenceMarker(source: source, variables: selector.variables, references: references)
        marker.traverse(selector.node, selector.dataID)
        references = marker.references
    }

    func traverse(_ node: NormalizationNode, _ dataID: DataID) {
        references.insert(dataID)
        guard let record = source[dataID] else {
            return
        }

        traverse(node.selections, record)
    }

    func traverse(_ selections: [NormalizationSelection], _ record: Record) {
        for selection in selections {
            switch selection {
            case .field(let field):
                if let field = field as? NormalizationLinkedField {
                    if field.plural {
                        traversePluralLink(field, record)
                    } else {
                        traverseLink(field, record)
                    }
                }
            case .handle(let handle):
                if handle.kind == .linked {
                    traverseLinkedHandle(handle, selections, record)
                }
            default:
                break
            }
        }
    }

    func traverseLink(_ field: NormalizationLinkedField, _ record: Record) {
        let storageKey = field.storageKey(from: variables)

        if let linkedID = record.getLinkedRecordID(storageKey), let linkedID2 = linkedID {
            traverse(field, linkedID2)
        }
    }

    func traversePluralLink(_ field: NormalizationLinkedField, _ record: Record) {
        let storageKey = field.storageKey(from: variables)

        if let linkedIDs = record.getLinkedRecordIDs(storageKey) {
            for linkedID in linkedIDs ?? [] {
                if let linkedID = linkedID {
                    traverse(field, linkedID)
                }
            }
        }
    }

    func traverseLinkedHandle(_ handle: NormalizationHandle, _ selections: [NormalizationSelection], _ record: Record) {
        let linkedFields = selections.compactMap { selection -> NormalizationLinkedField? in
            if case .field(let field) = selection, let field2 = field as? NormalizationLinkedField {
                return field2
            }
            return nil
        }
        guard let sourceField = linkedFields.first(where: {
            // TODO check args somehow
            $0.name == handle.name && $0.alias == handle.alias
        }) else {
            preconditionFailure("Expected a corresponding source field for handle `\(handle.handle)`")
        }

        let handleKey = handle.handleKey(from: variables)
        let field = NormalizationLinkedField(
            name: handleKey,
            alias: sourceField.alias,
            storageKey: handleKey,
            concreteType: sourceField.concreteType,
            plural: sourceField.plural,
            selections: sourceField.selections)

        if field.plural {
            traversePluralLink(field, record)
        } else {
            traverseLink(field, record)
        }
    }
}
