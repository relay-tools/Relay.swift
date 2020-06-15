public struct RefetchMetadata<Op: Operation> {
    public var fragmentPathInResult: [Any]
    public var operation: Op.Type
    public var connection: ConnectionMetadata?

    public init(path: [Any],
                operation: Op.Type,
                connection: ConnectionMetadata? = nil) {
        self.fragmentPathInResult = path
        self.operation = operation
        self.connection = connection
    }
}
