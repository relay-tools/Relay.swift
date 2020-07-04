import SnapshotTesting
@testable import Relay

extension FragmentPointer: AnySnapshotStringConvertible {
    public var snapshotDescription: String {
        "FragmentPointer(variables: \(String(reflecting: variables)), id: \(String(reflecting: id)), ownerIdentifier: \(String(reflecting: owner.identifier)), ownerVariables: \(String(reflecting: owner.variables)))"
    }
}
