---
title: Network layer
---

```swift
protocol Network
```

`Network` is a protocol that you implement in your app to control how your Relay.swift talks to your GraphQL API.

## Executing an operation

### `execute(request:variables:cacheConfig)`

```swift
func execute(
    request: RequestParameters,
    variables: VariableData,
    cacheConfig: CacheConfig
) -> AnyPublisher<Data, Error>
```

`Network` requires you to implement a single method, `execute`. Relay.swift will call this method when it needs to make a call to the GraphQL server. You are responsible for making the network call in whatever way makes sense for your app. You return the server's response to Relay.swift through a `Combine` publisher.

This gives you a great deal of flexibility around how your app talks to the server. We'll give a basic example using URLSession and a small Encodable struct, and that will probably be a good starting point for most apps. But you can also substitute another networking library, or even skip calling out to the network at all! The network layer is also a good place to address app-specific concerns like authentication.

#### Parameters

- `request`: A `RequestParameters` struct with useful properties for generating a GraphQL request body:
    - `name: String`: The operation name from the GraphQL query string. Usually sent in the `operationName` field in the request.
    - `operationKind: OperationKind`: An enum indicating what type of operation the request is for. Possible values: `.query`, `.mutation`, and `.subscription`, though subscriptions are not yet actually supported.
    - `text: String?`: The GraphQL source of the operation, including any necessary fragments. Usually sent in the `query` field in the request. Either `text` or `id` will be set.
    - `id: String?`: An identifier for the operation which the server can use to reference a persisted query, rather than having to send the whole query text. Relay.swift does not support persisted queries yet, so this will always be `nil` for now.
- `variables`: The variables for the operation. Usually sent in the `variables` field in the request. The `VariableData` type conforms to `Encodable`, so you can embed this directly in an `Encodable` struct to encode them as a JSON object.
- `cacheConfig`: Currently unused, but present here as a placeholder as it's part of the equivalent JavaScript API in Relay.

#### Returns

A Combine publisher that outputs `Data`. The data must be a valid JSON-formatted [GraphQL response](https://spec.graphql.org/June2018/#sec-Response).

## Examples

### Basic URLSession implementation

This is a great starting point for most apps, and can be customized as needed.

```swift
import Combine
import Foundation
import Relay

private let graphqlURL = URL(string: "https://www.example.org/graphql")!

struct RequestPayload: Encodable {
    var query: String
    var operationName: String
    var variables: VariableData
}

class Network: Relay.Network {
    func execute(request: RequestParameters, variables: VariableData, cacheConfig: CacheConfig) -> AnyPublisher<Data, Error> {
        var req = URLRequest(url: graphqlURL)
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpMethod = "POST"

        do {
            let payload = RequestPayload(query: request.text!, operationName: request.name, variables: variables)
            req.httpBody = try JSONEncoder().encode(payload)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }

        return URLSession.shared.dataTaskPublisher(for: req)
            .map { $0.data }
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
}
```

### Authentication with Auth0.swift

This example is based on a real app that uses Auth0 for authentication. For each request, it asks the Auth0 credentials manager for the current credentials. If the user's token is expired, the credentials manager may have to request a new one using a refresh token, so getting credentials is an asynchronous call. The network layer wraps this in a Combine `Future` and chains this into a data task publisher from URLSession once it has the credentials.

```swift
import Auth0
import Combine
import Foundation
import Relay

private let url = "https://example.org/graphql"

class Network: Relay.Network {
    let credentialsManager: CredentialsManager

    init(credentialsManager: CredentialsManager) {
        self.credentialsManager = credentialsManager
    }

    func execute(request: RequestParameters, variables: VariableData, cacheConfig: CacheConfig) -> AnyPublisher<Data, Error> {
        return Future<Credentials, Error> { promise in
            self.credentialsManager.credentials { error, creds in
                if let error = error {
                    promise(.failure(error as Error))
                } else {
                    promise(.success(creds!))
                }
            }
        }.flatMap { credentials -> AnyPublisher<Data, Error> in
            var req = URLRequest(url: self.endpoint.url)
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpMethod = "POST"
            req.setValue("Bearer \(credentials.accessToken!)", forHTTPHeaderField: "Authorization")

            do {
                let payload = RequestPayload(query: request.text ?? "", operationName: request.name, variables: variables)
                req.httpBody = try JSONEncoder().encode(payload)
            } catch {
                return Fail(error: error).eraseToAnyPublisher()
            }

            return URLSession.shared.dataTaskPublisher(for: req)
                .map { $0.data }
                .mapError { $0 as Error }
                .eraseToAnyPublisher()
        }.eraseToAnyPublisher()
    }
}

struct RequestPayload: Encodable {
    var query: String
    var operationName: String
    var variables: VariableData
}
```