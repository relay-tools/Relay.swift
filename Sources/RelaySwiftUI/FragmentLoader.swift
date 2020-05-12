import Combine
import Foundation
import Relay

class FragmentLoader<Fragment: Relay.Fragment>: ObservableObject {
    var environment: Environment!
    let fragment: Fragment

    var snapshot: Snapshot<Fragment.Data?>? {
        willSet {
            self.objectWillChange.send()
        }
    }

    private var subscribeCancellable: AnyCancellable?

    init(fragment: Fragment) {
        self.fragment = fragment
    }

    private var isLoaded = false

    func load(from environment: Environment, key: Fragment.Key) {
        guard !isLoaded else { return }

        self.environment = environment
        let pointer = fragment.getFragmentPointer(key)
        let selector = SingularReaderSelector(fragment: fragment.node, pointer: pointer)
        snapshot = environment.lookup(selector: selector)
        subscribe()
        isLoaded = true
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
