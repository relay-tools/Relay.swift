import Combine
import Relay

class FragmentLoader<Fragment: Relay.Fragment>: ObservableObject {
    let environment: Environment
    let fragment: Fragment
    let pointer: FragmentPointer

    @Published var snapshot: Snapshot<Fragment.Data?>

    init(environment: Environment,
         fragment: Fragment,
         pointer: FragmentPointer) {
        self.environment = environment
        self.fragment = fragment
        self.pointer = pointer

        let selector = SingularReaderSelector(fragment: fragment.node, pointer: pointer)
        snapshot = environment.lookup(selector: selector)
    }

    var data: Fragment.Data {
        snapshot.data!
    }
}
