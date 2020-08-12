import Combine

class OperationTracker {
    var inflightOperationIDs = Set<String>()
    private var ownersToPendingOperations: [RequestDescriptor: Set<RequestDescriptor>] = [:]
    private var pendingOperationsToOwners: [RequestDescriptor: Set<RequestDescriptor>] = [:]
    private var ownersToPromise: [RequestDescriptor: CachedPromise] = [:]

    func start(request: RequestDescriptor) {
        inflightOperationIDs.insert(request.identifier)
    }

    func update(pendingOperation: RequestDescriptor, affectedOwners: Set<RequestDescriptor>) {
        guard !affectedOwners.isEmpty else {
            return
        }

        let newlyAffectedOwners = affectedOwners.filter { owner in
            !(ownersToPendingOperations[owner]?.contains(pendingOperation) ?? false)
        }

        guard !newlyAffectedOwners.isEmpty else {
            return
        }

        var ownersAffectedByOperation = pendingOperationsToOwners[pendingOperation] ?? Set()

        for owner in newlyAffectedOwners {
            ownersToPendingOperations[owner, default: Set()].insert(pendingOperation)
            resolvePromise(owner: owner)
            ownersAffectedByOperation.insert(owner)
        }

        pendingOperationsToOwners[pendingOperation] = ownersAffectedByOperation
    }

    func complete(request: RequestDescriptor) {
        inflightOperationIDs.remove(request.identifier)

        guard let affectedOwners = pendingOperationsToOwners[request] else {
            return
        }

        var completedOwners = Set<RequestDescriptor>()
        var updatedOwners = Set<RequestDescriptor>()

        for owner in affectedOwners {
            guard var pendingOperationsAffectingOwner = ownersToPendingOperations[owner] else {
                continue
            }

            pendingOperationsAffectingOwner.remove(request)
            if pendingOperationsAffectingOwner.isEmpty {
                completedOwners.insert(owner)
            } else {
                updatedOwners.insert(owner)
            }
            ownersToPendingOperations[owner] = pendingOperationsAffectingOwner
        }

        for owner in completedOwners {
            resolvePromise(owner: owner)
            ownersToPendingOperations.removeValue(forKey: owner)
        }

        for owner in updatedOwners {
            resolvePromise(owner: owner)
        }

        pendingOperationsToOwners.removeValue(forKey: request)
    }

    func isActive(request: RequestDescriptor) -> Bool {
        inflightOperationIDs.contains(request.identifier)
    }

    func publisherForPendingOperations(owner: RequestDescriptor) -> AnyPublisher<Void, Never>? {
        guard ownersToPendingOperations[owner] != nil else {
            return nil
        }

        if let cachedPromise = ownersToPromise[owner] {
            return cachedPromise.future.eraseToAnyPublisher()
        }

        var promise: Future<Void, Never>.Promise?
        let future = Future<Void, Never> { thePromise in
            promise = thePromise
        }
        ownersToPromise[owner] = CachedPromise(future: future, promise: promise!)
        return future.eraseToAnyPublisher()
    }

    private func resolvePromise(owner: RequestDescriptor) {
        if let cachedPromise = ownersToPromise[owner] {
            cachedPromise.promise(.success(()))
            ownersToPromise.removeValue(forKey: owner)
        }
    }

    struct CachedPromise {
        var future: Future<Void, Never>
        var promise: Future<Void, Never>.Promise
    }
}
