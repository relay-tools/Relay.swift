public struct Snapshot<T>: Equatable {
    public var data: T { dataBox.get() }

    private var dataBox: DataBox
    public var isMissingData: Bool
    var seenRecords: [DataID: Record]
    public var selector: SingularReaderSelector

    init(data: SelectorData?,
         reify: @escaping (SelectorData?) -> T,
         isMissingData: Bool,
         seenRecords: [DataID: Record],
         selector: SingularReaderSelector) {
        self.dataBox = DataBox(selectorData: data, reify: reify)
        self.isMissingData = isMissingData
        self.seenRecords = seenRecords
        self.selector = selector
    }

    private final class DataBox {
        let selectorData: SelectorData?
        let reify: (SelectorData?) -> T
        var data: T?

        init(selectorData: SelectorData?, reify: @escaping (SelectorData?) -> T) {
            self.selectorData = selectorData
            self.reify = reify
        }

        func get() -> T {
            if let data = data {
                return data
            }

            data = reify(selectorData)
            return data!
        }
    }

    public static func ==(lhs: Self, rhs: Self) -> Bool {
        lhs.dataBox.selectorData == rhs.dataBox.selectorData && lhs.selector.dataID == rhs.selector.dataID && lhs.selector.owner == rhs.selector.owner
    }
}
