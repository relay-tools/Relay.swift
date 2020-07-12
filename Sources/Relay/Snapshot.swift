public struct Snapshot<T>: Equatable {
    public let data: T
    private let selectorData: SelectorData?
    public var isMissingData: Bool
    var seenRecords: [DataID: Record]
    public var selector: SingularReaderSelector

    init(data: SelectorData?,
         reify: (SelectorData?) -> T,
         isMissingData: Bool,
         seenRecords: [DataID: Record],
         selector: SingularReaderSelector) {
        self.selectorData = data
        self.data = reify(data)
        self.isMissingData = isMissingData
        self.seenRecords = seenRecords
        self.selector = selector
    }

    public static func ==(lhs: Self, rhs: Self) -> Bool {
        lhs.selectorData == rhs.selectorData &&
            lhs.selector.dataID == rhs.selector.dataID &&
            lhs.selector.owner == rhs.selector.owner
    }
}
