struct ResponsePayload {
    var errors: [GraphQLError]?
    var fieldPayloads: [HandleFieldPayload]
    // TODO other payloads
    var source: RecordSource
    var isFinal: Bool
}

public struct HandleFieldPayload {
    var args: VariableData
    var dataID: DataID
    var fieldKey: String
    var handle: String
    var handleKey: String
    var handleArgs: VariableData
}
