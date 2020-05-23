import SwiftUI
import Relay

public struct Inspector: View {
    @RelayEnvironment var environment: Relay.Environment

    public init() {}

    public var body: some View {
        List {
            Section {
                RecordRow(record: store.source[.rootID]!)
            }

            Section {
                ForEach(sortedRecordIDs, id: \.self) { recordID -> AnyView in
                    if let record = self.store.source[recordID] {
                        return AnyView(RecordRow(record: record))
                    } else {
                        // TODO show its ID though
                        return AnyView(Text("Missing record"))
                    }
                }
            }
        }
            .navigationBarTitle("Relay Store", displayMode: .inline)
            .listStyle(PlainListStyle())
    }

    private var store: Store {
        environment.store
    }

    private var sortedRecordIDs: [DataID] {
        store.source.recordIDs.sorted()
    }
}

struct RecordRow: View {
    let record: Record

    var body: some View {
        NavigationLink(destination: RecordDetail(record: record)) {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.typename)
                    .font(.headline)
                Text(record.dataID.rawValue)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }.padding(.vertical, 8)
        }
    }
}

struct RecordDetail: View {
    let record: Record

    var body: some View {
        List {
            Section(header: Text("DATA ID")) {
                Text(record.dataID.rawValue)
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            Section(header: Text("FIELDS")) {
                if record.fields.isEmpty {
                    Text("No fields").foregroundColor(.secondary)
                } else {
                    ForEach(record.fields.keys.sorted(), id: \.self) { key in
                        RecordFieldRow(self.record, key)
                    }
                }
            }
        }
            .navigationBarTitle(record.typename)
            .listStyle(GroupedListStyle())
    }
}

struct RecordFieldRow: View {
    @RelayEnvironment var environment: Relay.Environment
    let record: Record
    let key: String

    init(_ record: Record, _ key: String) {
        self.record = record
        self.key = key
    }

    var body: some View {
        if let destination = destinationView {
            return AnyView(NavigationLink(destination: destination) {
                LabeledRow(key, valueView)
            })
        } else {
            return AnyView(LabeledRow(key, valueView))
        }
    }

    var valueView: Text {
        switch record.fields[key]! {
        case .null:
            return Text("null")
                .font(.system(.body, design: .monospaced))
        case .bool(let value):
            return Text(value ? "true" : "false")
                .font(.system(.body, design: .monospaced))
        case .int(let value):
            return Text("\(value)")
        case .float(let value):
            return Text("\(value)")
        case .string(let value):
            return Text(verbatim: value)
        case .array(let values):
            return Text("\(values.count) scalars")
        case .linkedRecord:
            return Text("")
        case .linkedRecords(let ids):
            return Text("\(ids.count) records")
        }
    }

    var destinationView: AnyView? {
        switch record.fields[key]! {
        case .linkedRecord(let id):
            guard let record = environment.store.source[id] else {
                return AnyView(Text("Record missing"))
            }
            return AnyView(RecordDetail(record: record))
        case .linkedRecords(let ids):
            let records = ids.map { id in
                id.flatMap { environment.store.source[$0] }
            }
            return AnyView(RecordList(records: records))
        default:
            return nil
        }
    }
}

struct RecordList: View {
    let records: [Record?]

    var body: some View {
        List(records.indices) { idx -> AnyView in
            if let record = self.records[idx] {
                return AnyView(RecordRow(record: record))
            } else {
                return AnyView(Text("null").font(.system(.body, design: .monospaced)))
            }
        }.listStyle(PlainListStyle())
    }
}

struct LabeledRow: View {
    let label: String
    let value: Text

    init(_ label: String, _ value: Text) {
        self.label = label
        self.value = value
    }

    var body: some View {
        HStack {
            Text(label).font(.body)
            Spacer()
            value
                .lineLimit(1)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }
}
