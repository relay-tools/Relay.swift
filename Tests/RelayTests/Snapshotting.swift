import SnapshotTesting
@testable import Relay

extension Snapshotting where Value == RecordSource {
    static var recordSource: Snapshotting<Value, String> {
        Snapshotting<DefaultRecordSource, String>.json.pullback { recordSource in
            var newSource = DefaultRecordSource()

            // first, go through records in deterministic order, and record the local IDs we see along
            // the way
            var seenIDs = Set<DataID>()
            var orderedIDs: [DataID] = []

            for id in recordSource.recordIDs.sorted() {
                guard !id.isClientGenerated, let record = recordSource[id] else {
                    continue
                }

                for key in record.fields.keys.sorted() {
                    let val = record.fields[key]!

                    switch val {
                    case .linkedRecord(let id):
                        if id.isClientGenerated && !seenIDs.contains(id) {
                            seenIDs.insert(id)
                            orderedIDs.append(id)
                        }
                    case .linkedRecords(let ids):
                        let allIDs = ids.compactMap { $0 }.filter { $0.isClientGenerated && !seenIDs.contains($0) }
                        seenIDs.formUnion(allIDs)
                        orderedIDs.append(contentsOf: allIDs)
                    default:
                        continue
                    }
                }
            }

            // now we basically need to do a breadth-first search of the graph, so we catch
            // local IDs referenced inside other records with local IDs
            var idsToCheck = orderedIDs
            while !idsToCheck.isEmpty {
                let id = idsToCheck.removeFirst()

                guard let record = recordSource[id] else {
                    continue
                }

                for key in record.fields.keys.sorted() {
                    let val = record.fields[key]!

                    switch val {
                    case .linkedRecord(let id):
                        if id.isClientGenerated && !seenIDs.contains(id) {
                            seenIDs.insert(id)
                            orderedIDs.append(id)
                            idsToCheck.append(id)
                        }
                    case .linkedRecords(let ids):
                        let allIDs = ids.compactMap { $0 }.filter { $0.isClientGenerated && !seenIDs.contains($0) }
                        seenIDs.formUnion(allIDs)
                        orderedIDs.append(contentsOf: allIDs)
                        idsToCheck.append(contentsOf: allIDs)
                    default:
                        continue
                    }
                }
            }

            // now generate new IDs for the ones we saw based on the order we saw them
            let idMap: [DataID: DataID] = Dictionary(uniqueKeysWithValues: orderedIDs.enumerated().map { tuple in (tuple.element, DataID("client:local:\(tuple.offset)")) })

            // then copy records into the new record source using their new IDs
            for id in recordSource.recordIDs {
                guard var record = recordSource[id] else {
                    continue
                }

                if id.isClientGenerated {
                    guard let subID = idMap[id] else {
                        continue
                    }
                    record.dataID = subID
                }

                for (key, val) in record.fields {
                    switch val {
                    case .linkedRecord(let id):
                        if let subID = idMap[id] {
                            record.setLinkedRecordID(key, subID)
                        }
                    case .linkedRecords(let ids):
                        let newIDs = ids.map {
                            $0.map { idMap[$0] ?? $0 }
                        }
                        record.setLinkedRecordIDs(key, newIDs)
                    default:
                        continue
                    }
                }

                newSource[record.dataID] = record
            }

            newSource.deletedRecordIDs = Set(recordSource.recordIDs.filter { recordSource.getStatus($0) == .nonexistent })
            return newSource
        }
    }
}

extension FragmentPointer: AnySnapshotStringConvertible {
    public var snapshotDescription: String {
        "FragmentPointer(variables: \(String(reflecting: variables)), id: \(String(reflecting: id)), ownerIdentifier: \(String(reflecting: owner.identifier)), ownerVariables: \(String(reflecting: owner.variables)))"
    }
}
