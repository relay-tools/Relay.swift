import Combine
import Foundation
import Relay

class FragmentLoader<Fragment: Relay.Fragment>: ObservableObject {
    let environment: Environment
    let fragment: Fragment
    let pointer: FragmentPointer

    @Published var snapshot: Snapshot<Fragment.Data?>

    private var subscribeCancellable: AnyCancellable?

    init(environment: Environment,
         fragment: Fragment,
         pointer: FragmentPointer) {
        self.environment = environment
        self.fragment = fragment
        self.pointer = pointer

        let selector = SingularReaderSelector(fragment: fragment.node, pointer: pointer)
        snapshot = environment.lookup(selector: selector)
        subscribe()
    }

    var data: Fragment.Data? {
        snapshot.data
    }

    var isMissingData: Bool {
        snapshot.isMissingData
    }

    func subscribe() {
        subscribeCancellable = environment.subscribe(snapshot: snapshot)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] snapshot in
                self?.snapshot = snapshot
            }
    }
}
