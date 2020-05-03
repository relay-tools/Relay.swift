public protocol Record {
    var dataID: DataID { get set }
    var typename: String { get set }
}

public struct RootRecord: Record {
    public var dataID: DataID = .rootID
    public var typename = "__Root"
}
