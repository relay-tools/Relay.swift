public struct RefetchMetadata<Op: Operation> {
    public var fragmentPathInResult: [Any]
    public var identifierField: String?
    public var operation: Op.Type
    public var connection: ConnectionMetadata?

    public init(path: [Any],
                identifierField: String? = nil,
                operation: Op.Type,
                connection: ConnectionMetadata? = nil) {
        self.fragmentPathInResult = path
        self.identifierField = identifierField
        self.operation = operation
        self.connection = connection
    }
}
