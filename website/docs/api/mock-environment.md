---
title: MockEnvironment
---

```swift
class MockEnvironment: Environment
```

A `MockEnvironment` is a special [Environment](environment.md) subclass that has special support injecting data into the store and faking network responses. A mock environment is intended to be used for things like unit tests or SwiftUI previews (see [previewPayload()](preview-payload.mdx) for the latter).

## Creating a mock environment

### `init`

```swift
init(
  handlerProvider: HandlerProvider = DefaultHandlerProvider()
)
```

You don't need to pass a [network layer](network.md) or [store](store.md) when creating a mock environment. A mock environment always starts with an empty store, and it includes a special network layer intended for mocking.

## Loading data into the store

### `cachePayload(_:_:)`

```swift
func cachePayload<O: Operation>(
  _ operation: O,
  _ payload: [String: Any]
)
```

The `cachePayload` method loads a response to a particular query directly into the store. This doesn't use the [network layer](network.md) layer at all. This works well when you need to read a fragment from the store.

Note that even if you just want to read a fragment, you still need to have a query that includes it, and you need to supply a payload for the entire query. This is because queries are what determine how data gets normalized into the store: a fragment alone doesn't have enough information to write its data, only to read it.

## Faking network responses

### `mockResponse(_:_:)`

```swift
func mockResponse<O: Operation>(
  _ operation: O,
  _ payload: [String: Any]
)
```

The `mockResponse` method stores a payload to be returned from the network layer when something tries to execute the given operation. For example, if you're testing a view that uses a [@Query](query.md), you can use this to set up the response to the query before rendering the view.

To use the response, the operation must be for the same query with the same variables.

### `delayMockedResponse(_:_:)`

```swift
func delayMockedResponse<O: Operation>(
  _ operation: O,
  _ payload: [String: Any]
) -> (() -> Void)
```

The `delayMockedResponse` is similar to `mockResponse`, but it gives you control over when the fake network response is returned to Relay. It returns an `advance` function that your code can call when it wants the fake network response to complete. Until the `advance` function is called, the network response will be in-flight.