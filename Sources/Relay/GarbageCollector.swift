import Combine
import Foundation
import os

private let log = OSLog(subsystem: "io.github.mjm.Relay", category: "garbage-collection")

#if swift(>=5.3)
@available(iOS 14.0, macOS 10.16, tvOS 14.0, watchOS 7.0, *)
private let logger = Logger(log)
#endif

class GarbageCollector {
    let store: Store
    let releaseBufferSize: Int

    private let scheduler: DispatchQueue
    private var shouldSchedule = false
    private var isRunning = false
    private var holdCounter = 0
    private(set) var roots: [String: Entry] = [:]
    private var releaseBuffer: [String] = []

    init(
        store: Store,
        releaseBufferSize: Int = 0,
        scheduler: DispatchQueue = DispatchQueue(label: "relay-garbage-collector")
    ) {
        self.store = store
        self.releaseBufferSize = releaseBufferSize
        self.scheduler = scheduler
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

            #if swift(>=5.3)
            if #available(iOS 14.0, macOS 10.16, tvOS 14.0, watchOS 7.0, *) {
                logger.debug("GC Refcount: \(self.roots[id]?.refCount ?? 0, privacy: .public) \(operation.request.node.params.name, privacy: .public)\(operation.request.variables)")
                logger.info("GC Release: \(operation.request.node.params.name, privacy: .public)\(operation.request.variables)")
            }
            #endif
            os_signpost(.event, log: log, name: "release operation", signpostID: signpostID)
            self.roots[id]?.refCount -= 1

            if let root = self.roots[id], root.refCount == 0 {
                // TODO query cache expiration time
                self.releaseBuffer.append(id)
                if self.releaseBuffer.count > self.releaseBufferSize {
                    self.roots.removeValue(forKey: self.releaseBuffer.removeFirst())
                    self.schedule()
                }
            }
        }

        #if swift(>=5.3)
        if #available(iOS 14.0, macOS 10.16, tvOS 14.0, watchOS 7.0, *) {
            logger.debug("GC Refcount: \(self.roots[id]?.refCount ?? 0, privacy: .public) \(operation.request.node.params.name, privacy: .public)\(operation.request.variables)")
            logger.info("GC Retain:  \(operation.request.node.params.name, privacy: .public)\(operation.request.variables)")
        }
        #endif
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

        if operation.request.node.params.operationKind == .query && releaseBufferSize > 0 && releaseBuffer.count < releaseBufferSize {
            releaseBuffer.append(id)
            roots[id] = Entry(operation: operation, refCount: 0, epoch: store.currentWriteEpoch, fetchTime: Date())
        }
    }

    func pause() -> AnyCancellable {
        if isRunning {
            shouldSchedule = true
        }
        holdCounter += 1

        #if swift(>=5.3)
        if #available(iOS 14.0, macOS 10.16, tvOS 14.0, watchOS 7.0, *) {
            let holdCounter = self.holdCounter
            logger.info("GC Pause   (hold counter: \(holdCounter))")
        }
        #endif
        os_signpost(.event, log: log, name: "pause")

        return AnyCancellable {
            if self.holdCounter > 0 {
                self.holdCounter -= 1

                #if swift(>=5.3)
                if #available(iOS 14.0, macOS 10.16, tvOS 14.0, watchOS 7.0, *) {
                    let holdCounter = self.holdCounter
                    logger.info("GC Unpause (hold counter: \(holdCounter))")
                }
                #endif
                os_signpost(.event, log: log, name: "unpause")

                if self.holdCounter == 0 && self.shouldSchedule {
                    self.schedule()
                    self.shouldSchedule = false
                }
            } else {
                #if swift(>=5.3)
                if #available(iOS 14.0, macOS 10.16, tvOS 14.0, watchOS 7.0, *) {
                    logger.error("GC Unpause when hold counter is already 0")
                }
                #endif
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

        #if swift(>=5.3)
        if #available(iOS 14.0, macOS 10.16, tvOS 14.0, watchOS 7.0, *) {
            logger.notice("GC Schedule")
        }
        #endif
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

            #if swift(>=5.3)
            let referencesBefore = references.count
            #endif

            ReferenceMarker.mark(
                source: store.recordSource,
                selector: selector,
                references: &references)

            let currentEpoch = store.currentWriteEpoch
            if startEpoch != currentEpoch {
                #if swift(>=5.3)
                if #available(iOS 14.0, macOS 10.16, tvOS 14.0, watchOS 7.0, *) {
                    logger.info("GC Restart: store updated while collecting (start epoch: \(startEpoch), current epoch: \(currentEpoch))")
                }
                #endif
                os_signpost(.event, log: log, name: "restart garbage collection", signpostID: signpostID)
                return false
            }

            if shouldSchedule {
                #if swift(>=5.3)
                if #available(iOS 14.0, macOS 10.16, tvOS 14.0, watchOS 7.0, *) {
                    logger.info("GC Cancel: paused while collecting")
                }
                #endif
                os_signpost(.event, log: log, name: "cancel garbage collection", signpostID: signpostID)
                return true
            }

            #if swift(>=5.3)
            if #available(iOS 14.0, macOS 10.16, tvOS 14.0, watchOS 7.0, *) {
                let referencesAfter = references.count
                logger.debug("GC Mark Root:  \(rootEntry.operation.request.node.params.name)\(rootEntry.operation.request.variables)  added \(referencesAfter - referencesBefore) new references")
            }
            #endif
        }

        // hop back onto the main queue while we update the store
        return DispatchQueue.main.sync {
            // check this again now that we're on the main queue.
            // after this, nothing should be able to interrupt us, because updates
            // to the store should all happen on the main queue.
            let currentEpoch = store.currentWriteEpoch
            if startEpoch != currentEpoch {
                #if swift(>=5.3)
                if #available(iOS 14.0, macOS 10.16, tvOS 14.0, watchOS 7.0, *) {
                    logger.info("GC Restart: store updated while collecting (start epoch: \(startEpoch), current epoch: \(currentEpoch))")
                }
                #endif
                os_signpost(.event, log: log, name: "restart garbage collection", signpostID: signpostID)
                return false
            }

            if shouldSchedule {
                #if swift(>=5.3)
                if #available(iOS 14.0, macOS 10.16, tvOS 14.0, watchOS 7.0, *) {
                    logger.info("GC Cancel: paused while collecting")
                }
                #endif
                os_signpost(.event, log: log, name: "cancel garbage collection", signpostID: signpostID)
                return true
            }

            if references.isEmpty {
                store.recordSource.clear()
                #if swift(>=5.3)
                if #available(iOS 14.0, macOS 10.16, tvOS 14.0, watchOS 7.0, *) {
                    logger.notice("GC Result:  0 references found, cleared entire store")
                }
                #endif
            } else {
                var deletedCount = 0
                var deletedByTypeName: [String: Int] = [:]

                for dataID in store.recordSource.recordIDs {
                    if !references.contains(dataID) {
                        let typeName = store.recordSource[dataID]!.typename
                        store.recordSource.remove(dataID)
                        deletedCount += 1
                        deletedByTypeName[typeName] = (deletedByTypeName[typeName] ?? 0) + 1
                    }
                }
                #if swift(>=5.3)
                if #available(iOS 14.0, macOS 10.16, tvOS 14.0, watchOS 7.0, *) {
                    logger.notice("GC Result:  \(references.count) references found, deleted \(deletedCount) records")
                    for (typeName, count) in deletedByTypeName {
                        logger.debug("GC Result:  \(count) \(typeName) records deleted")
                    }
                }
                #endif
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
            case .inlineFragment(let fragment):
                if fragment.type == record.typename {
                    traverse(fragment.selections, record)
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
        let field = handle.clonedSourceField(selections: selections, variables: variables)
        if field.plural {
            traversePluralLink(field, record)
        } else {
            traverseLink(field, record)
        }
    }
}
