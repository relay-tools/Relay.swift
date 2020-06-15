public struct ConnectionConfig {
    public var clientMutationID: String
    public var cursor: String
    public var edges: String
    public var endCursor: String
    public var hasNextPage: String
    public var hasPreviousPage: String
    public var node: String
    public var pageInfoType: String
    public var pageInfo: String
    public var startCursor: String

    public static let `default` = ConnectionConfig(
        clientMutationID: "clientMutationID",
        cursor: "cursor",
        edges: "edges",
        endCursor: "endCursor",
        hasNextPage: "hasNextPage",
        hasPreviousPage: "hasPreviousPage",
        node: "node",
        pageInfoType: "PageInfo",
        pageInfo: "pageInfo",
        startCursor: "startCursor"
    )
}
