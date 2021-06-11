import Combine
import Foundation

/// A type that defines how Relay talks to your GraphQL API.
public protocol Network {
    /// Perform a single request to a GraphQL API.
    ///
    /// Relay.swift will call this method when it needs to make a call to the GraphQL server. You are responsible for making the network call in whatever way makes sense for your app. You return the server's response to Relay.swift through a `Combine` publisher.
    ///
    /// This gives you a great deal of flexibility around how your app talks to the server. We'll give a basic example using `URLSession` and a small Encodable struct, and that will probably be a good starting point for most apps. But you can also substitute another networking library, or even skip calling out to the network at all! The network layer is also a good place to address app-specific concerns like authentication.
    func execute(
        request: RequestParameters,
        variables: VariableData,
        cacheConfig: CacheConfig
    ) -> AnyPublisher<Data, Error>
}
