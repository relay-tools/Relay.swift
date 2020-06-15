public struct GraphQLResponse {
    public var data: [String: Any]?
    public var errors: [GraphQLError]?
    public var extensions: [String: Any]?

    init(data: [String: Any]? = nil, errors: [GraphQLError]? = nil, extensions: [String: Any]? = nil) {
        self.data = data
        self.errors = errors
        self.extensions = extensions
    }

    init(dictionary: [String: Any]) throws {
        if let data = dictionary["data"] {
            guard let data = data as? [String: Any] else {
                throw DecodingError.typeMismatch([String: Any]?.self, .init(codingPath: [], debugDescription: ""))
            }
            self.data = data
        }

        if let errors = dictionary["errors"] {
            guard let errors = errors as? [[String: Any]] else {
                throw DecodingError.typeMismatch([[String: Any]]?.self, .init(codingPath: [], debugDescription: ""))
            }

            self.errors = try errors.map { error in
                guard let error = GraphQLError(dictionary: error) else {
                    throw DecodingError.typeMismatch([String: Any]?.self, .init(codingPath: [], debugDescription: ""))
                }
                return error
            }
        }

        if let extensions = dictionary["extensions"] {
            guard let extensions = extensions as? [String: Any] else {
                throw DecodingError.typeMismatch([String: Any]?.self, .init(codingPath: [], debugDescription: ""))
            }
            self.extensions = extensions
        }
    }
}
