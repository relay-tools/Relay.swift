public struct SingularReaderSelector {
    var dataID: DataID
    var node: ReaderFragment
    public var owner: RequestDescriptor
    public var variables: VariableData

    init(dataID: DataID, node: ReaderFragment, owner: RequestDescriptor, variables: VariableData) {
        self.dataID = dataID
        self.node = node
        self.owner = owner
        self.variables = variables
    }

    public init(fragment: ReaderFragment, pointer: FragmentPointer) {
        dataID = pointer.id
        node = fragment
        owner = pointer.owner
        variables = pointer.variables
    }
}
