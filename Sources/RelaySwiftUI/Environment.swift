import SwiftUI
import Relay

struct RelayEnvironmentKey: EnvironmentKey {
    static var defaultValue: Relay.Environment? { nil }
}

struct QueryResourceKey: EnvironmentKey {
    static var defaultValue: QueryResource? { nil }
}

extension EnvironmentValues {
    public var relayEnvironment: Relay.Environment? {
        get { self[RelayEnvironmentKey.self] }
        set { self[RelayEnvironmentKey.self] = newValue }
    }

    var queryResource: QueryResource? {
        get { self[QueryResourceKey.self] }
        set { self[QueryResourceKey.self] = newValue }
    }
}

public struct WithRelayEnvironment: ViewModifier {
    let environment: Relay.Environment

    public func body(content: Content) -> some View {
        content
            .environment(\.relayEnvironment, environment)
            .environment(\.queryResource, QueryResource(environment: environment))
    }
}

public extension View {
    func relayEnvironment(_ environment: Relay.Environment) -> some View {
        modifier(WithRelayEnvironment(environment: environment))
    }
}

@propertyWrapper
public struct RelayEnvironment: DynamicProperty {
    @SwiftUI.Environment(\.relayEnvironment) var environment

    public init() {}

    public var wrappedValue: Relay.Environment {
        environment!
    }
}
