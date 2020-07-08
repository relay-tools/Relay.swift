class DataChecker {
    enum Availability {
        case available(Int?)
        case missing(Int?)

        var mostRecentlyInvalidatedAt: Int? {
            switch self {
            case .available(let epoch), .missing(let epoch):
                return epoch
            }
        }
    }

    let source: RecordSource
    let mutator: RecordSourceMutator
    let variables: VariableData

    private var mostRecentlyInvalidatedAt: Int?
    private var recordWasMissing = false

    init(
        source: RecordSource,
        variables: VariableData
    ) {
        self.source = source
        self.mutator = RecordSourceMutator(base: source, sink: DefaultRecordSource())
        self.variables = variables
    }

    class func check(source: RecordSource, selector: NormalizationSelector) -> Availability {
        DataChecker(
            source: source,
            variables: selector.variables
        ).check(node: selector.node, dataID: selector.dataID)
    }

    func check(node: NormalizationNode, dataID: DataID) -> Availability {
        traverse(node, dataID)

        if recordWasMissing {
            return .missing(mostRecentlyInvalidatedAt)
        } else {
            return .available(mostRecentlyInvalidatedAt)
        }
    }

    private func traverse(_ node: NormalizationNode, _ dataID: DataID) {
        switch mutator.getStatus(dataID) {
        case .unknown:
            handleMissing()
        case .existent:
            let record = source[dataID]!
            if let invalidatedAt = record.invalidatedAt {
                mostRecentlyInvalidatedAt = max(invalidatedAt, mostRecentlyInvalidatedAt ?? Int.min)
            }
            traverse(selections: node.selections, dataID: dataID)
        case .nonexistent:
            return
        }
    }

    private func traverse(selections: [NormalizationSelection], dataID: DataID) {
        for selection in selections {
            switch selection {
            case .field(let field):
                if let field = field as? NormalizationScalarField {
                    check(scalar: field, dataID: dataID)
                } else if let field = field as? NormalizationLinkedField {
                    if field.plural {
                        check(pluralLink: field, dataID: dataID)
                    } else {
                        check(link: field, dataID: dataID)
                    }
                }
            case .inlineFragment(let fragment):
                if fragment.type == source[dataID]!.typename {
                    traverse(selections: fragment.selections, dataID: dataID)
                }
            case .handle(let handle):
                let field = handle.clonedSourceField(selections: selections, variables: variables)
                if field.plural {
                    check(pluralLink: field, dataID: dataID)
                } else {
                    check(link: field, dataID: dataID)
                }
            default:
                preconditionFailure("not implemented")
            }
        }
    }

    private func check(scalar field: NormalizationScalarField, dataID: DataID) {
        let storageKey = field.storageKey(from: variables)
        if mutator.getValue(dataID: dataID, key: storageKey) == nil {
            handleMissing()
        }
    }

    private func check(link field: NormalizationLinkedField, dataID: DataID) {
        let storageKey = field.storageKey(from: variables)
        if let linkedID = mutator.getLinkedRecordID(dataID: dataID, key: storageKey) {
            if let linkedID = linkedID {
                traverse(field, linkedID)
            }
        } else {
            handleMissing()
        }
    }

    private func check(pluralLink field: NormalizationLinkedField, dataID: DataID) {
        let storageKey = field.storageKey(from: variables)
        if let linkedIDs = mutator.getLinkedRecordIDs(dataID: dataID, key: storageKey) {
            if let linkedIDs = linkedIDs {
                for linkedID in linkedIDs.compactMap({ $0 }) {
                    traverse(field, linkedID)
                }
            }
        } else {
            handleMissing()
        }
    }

    private func handleMissing() {
        recordWasMissing = true
    }
}
