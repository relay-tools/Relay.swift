public protocol RecordSourceSelectorProxy: RecordSourceProxy {
    func getRootField(_ fieldName: String) -> RecordProxy?
    func getPluralRootField(_ fieldName: String) -> [RecordProxy?]?
}

class DefaultRecordSourceSelectorProxy: RecordSourceSelectorProxy {
    private let mutator: RecordSourceMutator
    private var recordSource: RecordSourceProxy
    private let readSelector: SingularReaderSelector

    init(mutator: RecordSourceMutator,
         recordSource: RecordSourceProxy,
         readSelector: SingularReaderSelector) {
        self.mutator = mutator
        self.recordSource = recordSource
        self.readSelector = readSelector
    }

    func create(dataID: DataID, typeName: String) -> RecordProxy {
        recordSource.create(dataID: dataID, typeName: typeName)
    }

    func delete(dataID: DataID) {
        recordSource.delete(dataID: dataID)
    }

    subscript(dataID: DataID) -> RecordProxy? {
        recordSource[dataID]
    }

    var root: RecordProxy {
        recordSource.root
    }

    func invalidateStore() {
        recordSource.invalidateStore()
    }

    private var operationRoot: RecordProxy {
        var root = recordSource[readSelector.dataID]
        if root == nil {
            root = recordSource.create(dataID: readSelector.dataID, typeName: Record.root.typename)
        }
        return root!
    }

    private func getLinkedField(_ fieldName: String, plural: Bool) -> ReaderLinkedField {
        for selection in readSelector.node.selections {
            guard case .field(let field) = selection, field.name == fieldName else {
                continue
            }

            guard let linkedField = field as? ReaderLinkedField else {
                preconditionFailure("Root field `\(fieldName)` is not a linked field")
            }

            precondition(linkedField.plural == plural, "Expected root field `\(fieldName)` to be \(plural ? "plural" : "singular")")
            return linkedField
        }

        preconditionFailure("Cannot find root field `\(fieldName)` on GraphQL document `\(readSelector.node.name)`")
    }

    func getRootField(_ fieldName: String) -> RecordProxy? {
        let field = getLinkedField(fieldName, plural: false)
        let storageKey = field.storageKey(from: readSelector.variables)
        return operationRoot.getLinkedRecord(storageKey)
    }

    func getPluralRootField(_ fieldName: String) -> [RecordProxy?]? {
        let field = getLinkedField(fieldName, plural: true)
        let storageKey = field.storageKey(from: readSelector.variables)
        return operationRoot.getLinkedRecords(storageKey)
    }
}
