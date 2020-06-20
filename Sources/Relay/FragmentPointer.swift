public struct FragmentPointer: Equatable, Decodable {
    var variables: VariableData
    var id: DataID
    var owner: RequestDescriptor

    init(variables: VariableData, id: DataID, owner: RequestDescriptor) {
        self.variables = variables
        self.id = id
        self.owner = owner
    }

    public init(from decoder: Decoder) throws {
        preconditionFailure("FragmentPointer can only be decoded by a SelectorDataDecoder")
    }
}
