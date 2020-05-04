public class Store {
    private var recordSource: RecordSource

    public init(source: RecordSource) {
        recordSource = source

        initializeRecordSource()
    }

    public var source: RecordSource {
        get {
            recordSource
        }
        set {
            recordSource = newValue
        }
    }

    private func initializeRecordSource() {
        if !recordSource.has(dataID: .rootID) {
            recordSource[.rootID] = RootRecord()
        }
    }
}
