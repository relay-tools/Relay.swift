struct OptimisticRecordSource: RecordSource {
    var base: RecordSource
    var sink: DefaultRecordSource

    init(base: RecordSource) {
        self.base = base
        self.sink = DefaultRecordSource()
    }
    
    subscript(_ dataID: DataID) -> Record? {
        get {
            if sink.has(dataID) {
                let record = sink[dataID]
                // TODO unpublish sentinel
                return record
            } else {
                return base[dataID]
            }
        }
        set {
            sink[dataID] = newValue
        }
    }

    var recordIDs: [DataID] {
        Array(Set<DataID>(base.recordIDs).union(sink.recordIDs))
    }

    func getStatus(_ dataID: DataID) -> RecordState {
        switch sink.getStatus(dataID) {
        case .existent:
            // TODO unpublish sentinel
            return .existent
        case .nonexistent:
            return .nonexistent
        case .unknown:
            return base.getStatus(dataID)
        }
    }

    func has(_ dataID: DataID) -> Bool {
        if sink.has(dataID) {
            // TODO unpublish sentinel
            return true
        } else {
            return base.has(dataID)
        }
    }

    var count: Int {
        recordIDs.count
    }

    mutating func remove(_ dataID: DataID) {
        // TODO
    }

    mutating func clear() {
        base = DefaultRecordSource()
        sink.clear()
    }
}

extension OptimisticRecordSource: Codable {
    enum CodingKeys: String, CodingKey {
        case base
        case sink
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        base = try container.decode(DefaultRecordSource.self, forKey: .base)
        sink = try container.decode(DefaultRecordSource.self, forKey: .sink)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let base = base as? DefaultRecordSource {
            try container.encode(base, forKey: .base)
        } else {
            preconditionFailure("Don't know how to encode record source of type \(type(of: base))")
        }
        try container.encode(sink, forKey: .sink)
    }
}
