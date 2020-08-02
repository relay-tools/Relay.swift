import Combine
import Foundation
import Relay

class FragmentLoader<Fragment: Relay.Fragment>: ObservableObject {
    var fragmentResource: FragmentResource!
    var selector: SingularReaderSelector?

    @Published var snapshot: Snapshot<Fragment.Data?>? {
        willSet {
            self.objectWillChange.send()
        }
    }

    private var subscribeCancellable: AnyCancellable?

    init() {}

    var environment: Environment {
        fragmentResource.environment
    }

    func load(from resource: FragmentResource, key: Fragment.Key) {
        self.fragmentResource = resource
        let selector = Fragment(key: key).selector
        self.selector = selector

        let result: FragmentResource.FragmentResult<Fragment.Data> =
            resource.read(selector: selector, identifier: selector.identifier)
        guard result.snapshot != snapshot else {
            return
        }

        snapshot = result.snapshot
        subscribeCancellable = resource.subscribe(result)
            .sink { [weak self] snapshot in
                self?.snapshot = snapshot
            }
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
}
