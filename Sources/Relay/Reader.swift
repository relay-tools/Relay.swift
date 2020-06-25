import Foundation
import os

@available(iOS 14.0, *)
private let logger = Logger(subsystem: "io.github.mjm.Relay", category: "reader")

class Reader {
    let recordSource: RecordSource
    let selector: SingularReaderSelector
    let owner: RequestDescriptor
    let variables: VariableData

    private var isMissingData = false
    private var seenRecords: [DataID: Record] = [:]

    init(source: RecordSource, selector: SingularReaderSelector) {
        self.recordSource = source
        self.selector = selector
        self.owner = selector.owner
        self.variables = selector.variables
    }

    static func read<T: Decodable>(_ type: T.Type, source: RecordSource, selector: SingularReaderSelector) -> Snapshot<T?> {
        Reader(source: source, selector: selector).read(type)
    }

    func read<T: Decodable>(_ type: T.Type) -> Snapshot<T?> {
        let data = traverse(node: selector.node, dataID: selector.dataID)
        return Snapshot(
            data: data,
            reify: { data in
                guard let data = data else { return nil }

                do {
                    return try SelectorDataDecoder().decode(type, from: data)
                } catch {
                    if #available(iOS 14.0, *) {
                        logger.debug("Decoding fragment data into \(String(reflecting: type), privacy: .public) failed (this may be harmless): \(error as NSError)")
                    }
                    return nil
                }
            },
            isMissingData: isMissingData,
            seenRecords: seenRecords,
            selector: selector
        )
    }

    private func traverse(node: ReaderNode, dataID: DataID, previousData: SelectorData? = nil) -> SelectorData? {
        guard let record = recordSource[dataID] else {
            if !recordSource.has(dataID) {
                isMissingData = true
            }
            return nil
        }
        seenRecords[dataID] = record

        var data = previousData ?? SelectorData()
        traverse(selections: node.selections, record: record, data: &data)
        return data
    }

    private func traverse(selections: [ReaderSelection], record: Record, data: inout SelectorData) {
        for selection in selections {
            switch selection {
            case .field(let field):
                if let field = field as? ReaderScalarField {
                    readScalar(for: field, from: record, into: &data)
                } else if let field = field as? ReaderLinkedField {
                    if field.plural {
                        readPluralLink(for: field, from: record, into: &data)
                    } else {
                        readLink(for: field, from: record, into: &data)
                    }
                } else {
                    preconditionFailure("Unexpected type of ReaderField: \(type(of: field))")
                }
            case .fragmentSpread(let fragmentSpread):
                createFragmentPointer(for: fragmentSpread, to: record, into: &data)
            case .inlineFragment(let inlineFragment):
                data.set("__typename", scalar: record.typename)
                if record.typename == inlineFragment.type {
                    traverse(selections: inlineFragment.selections, record: record, data: &data)
                }
            }
        }
    }

    private func readScalar(for field: ReaderScalarField, from record: Record, into data: inout SelectorData) {
        let storageKey = field.storageKey(from: variables)
        var value = record[storageKey]
        if value == nil {
            isMissingData = true
        } else if value is NSNull {
            value = nil
        }

        data.set(field.applicationName, scalar: value)
    }

    private func readLink(for field: ReaderLinkedField, from record: Record, into data: inout SelectorData) {
        let storageKey = field.storageKey(from: variables)
        guard let linkedID = record.getLinkedRecordID(storageKey) else {
            data.set(field.applicationName, object: nil)
            isMissingData = true
            return
        }

        guard let linkedID2 = linkedID else {
            data.set(field.applicationName, object: nil)
            return
        }

        let prevData = data.get(SelectorData?.self, field.applicationName)
        data.set(field.applicationName, object: traverse(node: field, dataID: linkedID2, previousData: prevData))
    }

    private func readPluralLink(for field: ReaderLinkedField, from record: Record, into data: inout SelectorData) {
        let storageKey = field.storageKey(from: variables)
        guard let linkedIDs = record.getLinkedRecordIDs(storageKey) else {
            data.set(field.applicationName, objects: nil)
            isMissingData = true
            return
        }

        guard let realLinkedIDs = linkedIDs else {
            data.set(field.applicationName, objects: nil)
            return
        }

        let prevData = data.get([SelectorData?]?.self, field.applicationName)

        var linkedArray: [SelectorData?] = Array(repeating: nil, count: realLinkedIDs.count)
        if let prevData = prevData {
            linkedArray[0..<prevData.count] = ArraySlice(prevData)
        }
        for (i, linkedID) in realLinkedIDs.enumerated() {
            guard let linkedID = linkedID else {
                // TODO missing data
                linkedArray[i] = nil
                continue
            }

            linkedArray[i] = traverse(node: field, dataID: linkedID, previousData: linkedArray[i])
        }
        data.set(field.applicationName, objects: linkedArray)
    }

    private func createFragmentPointer(for fragmentSpread: ReaderFragmentSpread, to record: Record, into data: inout SelectorData) {
        data.set(fragment: fragmentSpread.name,
                 variables: getArgumentValues(fragmentSpread.args ?? [], variables),
                 dataID: record.dataID,
                 owner: owner)
    }
}
