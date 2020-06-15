public struct OperationDescriptor {
    public let fragment: SingularReaderSelector
    public let request: RequestDescriptor
    let root: NormalizationSelector

    init(request: ConcreteRequest, variables: VariableData, requestDescriptor: RequestDescriptor, dataID: DataID) {
        self.fragment = SingularReaderSelector(dataID: dataID, node: request.fragment, owner: requestDescriptor, variables: variables)
        self.request = requestDescriptor
        self.root = NormalizationSelector(dataID: dataID, node: request.operation, variables: variables)
    }
}

struct NormalizationSelector {
    var dataID: DataID
    var node: NormalizationNode
    var variables: VariableData
}
