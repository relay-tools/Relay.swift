import SwiftUI
import Relay

struct RelayEnvironmentKey: EnvironmentKey {
    static var defaultValue: Relay.Environment? { nil }
}

public extension EnvironmentValues {
    public var relayEnvironment: Relay.Environment? {
        get { self[RelayEnvironmentKey.self] }
        set { self[RelayEnvironmentKey.self] = newValue }
    }
}
