class RecordSourceMutator {
    let base: RecordSource
    var sink: RecordSource

    init(base: RecordSource, sink: RecordSource) {
        self.base = base
        self.sink = sink
    }

    private var sources: [RecordSource] {
        [sink, base]
    }

    func getStatus(_ dataID: DataID) -> RecordState {
        sink.has(dataID) ? sink.getStatus(dataID) : base.getStatus(dataID)
    }

    func getType(_ dataID: DataID) -> String? {
        for source in sources {
            if let record = source[dataID] {
                return record.typename
            } else if source.getStatus(dataID) == .nonexistent {
                return nil
            }
        }
        return nil
    }

    func getValue(dataID: DataID, key: String) -> Any? {
        for source in sources {
            if let record = source[dataID] {
                return record[key]
            } else if source.getStatus(dataID) == .nonexistent {
                return nil
            }
        }
        return nil
    }

    func getLinkedRecordID(dataID: DataID, key: String) -> DataID? {
        for source in sources {
            if let record = source[dataID] {
                if let linkedID = record.getLinkedRecordID(key) {
                    return linkedID
                }
            } else if source.getStatus(dataID) == .nonexistent {
                return nil
            }
        }
        return nil
    }

    func getLinkedRecordIDs(dataID: DataID, key: String) -> [DataID?]? {
        for source in sources {
            if let record = source[dataID] {
                if let linkedIDs = record.getLinkedRecordIDs(key) {
                    return linkedIDs
                }
            } else if source.getStatus(dataID) == .nonexistent {
                return nil
            }
        }
        return nil
    }

    func setValue(dataID: DataID, key: String, value: Any?) {
        updateSinkRecord(dataID) { record in
            record[key] = value
        }
    }

    func setLinkedRecordID(dataID: DataID, key: String, linkedID: DataID) {
        updateSinkRecord(dataID) { record in
            record.setLinkedRecordID(key, linkedID)
        }
    }

    func setLinkedRecordIDs(dataID: DataID, key: String, linkedIDs: [DataID?]) {
        updateSinkRecord(dataID) { record in
            record.setLinkedRecordIDs(key, linkedIDs)
        }
    }

    func copyFields(from sourceID: DataID, to sinkID: DataID) {
        let sinkSource = sink[sourceID]
        let baseSource = base[sourceID]

        precondition(sinkSource != nil || baseSource != nil, "Cannot copy fields from non-existent record \(sourceID)")

        updateSinkRecord(sinkID) { record in
            if let source = baseSource {
                record.copyFields(from: source)
            }
            if let source = sinkSource {
                record.copyFields(from: source)
            }
        }
    }

    func create(dataID: DataID, typeName: String) {
        precondition(base.getStatus(dataID) != .existent && sink.getStatus(dataID) != .existent,
            "Cannot create a record with data ID \(dataID) because it already exists")

        sink[dataID] = Record(dataID: dataID, typename: typeName)
    }

    func delete(dataID: DataID) {
        sink[dataID] = nil
    }

    private func updateSinkRecord(_ dataID: DataID, _ updater: (inout Record) -> Void) {
        var record = sink[dataID]
        if record == nil {
            guard let baseRecord = base[dataID] else {
                preconditionFailure("Cannot modify non-existent record \(dataID)")
            }
            record = Record(dataID: dataID, typename: baseRecord.typename)
        }

        var sinkRecord = record!
        updater(&sinkRecord)
        sink[dataID] = sinkRecord
    }
}
