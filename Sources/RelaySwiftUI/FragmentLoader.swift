import Combine
import Foundation
import Relay

class FragmentLoader<Fragment: Relay.Fragment>: ObservableObject {
    var environment: Environment!
    var selector: SingularReaderSelector?

    @Published var snapshot: Snapshot<Fragment.Data?>? {
        willSet {
            self.objectWillChange.send()
        }
    }

    private var subscribeCancellable: AnyCancellable?

    init() {}

    func load(from environment: Environment, key: Fragment.Key) {
        let newSelector = Fragment(key: key).selector
        if newSelector == selector {
            return
        }

        self.environment = environment
        self.selector = newSelector
        snapshot = environment.lookup(selector: newSelector)
        subscribe()
    }

    var data: Fragment.Data? {
        guard let snapshot = snapshot else { return nil }

        if snapshot.isMissingData && environment.isActive(request: snapshot.selector.owner) {
            // wait for the request to finish to try to get complete data.
            // this can happen if we are loading query data from the store and we change the
            // query variables, such that some of the records in the tree still exist but not
            // all.
            return nil
        }

        return snapshot.data
    }

    func subscribe() {
        guard let snapshot = snapshot else { return }
        
        subscribeCancellable = environment.subscribe(snapshot: snapshot)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] snapshot in
                self?.snapshot = snapshot
            }
    }
}
