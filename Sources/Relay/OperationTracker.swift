class OperationTracker {
    var inflightOperationIDs = Set<String>()

    func start(request: RequestDescriptor) {
        inflightOperationIDs.insert(request.identifier)
    }

    func complete(request: RequestDescriptor) {
        inflightOperationIDs.remove(request.identifier)
    }

    func isActive(request: RequestDescriptor) -> Bool {
        inflightOperationIDs.contains(request.identifier)
    }
}
