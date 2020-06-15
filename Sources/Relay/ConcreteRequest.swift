public struct ConcreteRequest {
    var fragment: ReaderFragment
    var operation: NormalizationOperation
    var params: RequestParameters

    public init(fragment: ReaderFragment, operation: NormalizationOperation, params: RequestParameters) {
        self.fragment = fragment
        self.operation = operation
        self.params = params
    }
}
