public struct ConnectionMetadata {
    public var pathInFragment: [Any]
    public var backward: ConnectionVariableConfig?
    public var forward: ConnectionVariableConfig?

    public init(path: [Any],
                backward: ConnectionVariableConfig? = nil,
                forward: ConnectionVariableConfig? = nil) {
        self.pathInFragment = path
        self.backward = backward
        self.forward = forward
    }
}

public struct ConnectionVariableConfig {
    public var count: String
    public var cursor: String

    public init(count: String, cursor: String) {
        self.count = count
        self.cursor = cursor
    }
}
