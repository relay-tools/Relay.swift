public struct TaggedGraphQLQuery {
    public var query: String
}

public func graphql(_ query: String) -> TaggedGraphQLQuery {
    TaggedGraphQLQuery(query: query)
}
