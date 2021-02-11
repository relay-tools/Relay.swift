---
title: Environment
---

```swift
class Environment
```

The `Environment` combines all the things that Relay.swift needs to be able to work. You use an environment to fetch queries and load stored records. Any views in your app that need to use Relay will need access to the environment to do so.

## Creating an environment

### `init`

```swift
init(
	network: Network,
	store: Store,
	handlerProvider: HandlerProvider = DefaultHandlerProvider()
)
```

An environment needs two things at a minimum:

- A [Network Layer](network.md) to tell it how to communicate with your GraphQL API
- A [Store](store.md) for keeping track of data locally

Once you've created it, you probably want to keep the same Environment instance for the lifetime of your app. In SwiftUI, you can use [relayEnvironment()](relay-environment-modifier.md) to provide this to your views.

## Fetching data outside a view

### `fetchQuery`

```swift
func fetchQuery<Op: Operation>(
	_ operation: Op,
	cacheConfig: CacheConfig = .init()
) -> AnyPublisher<Op.Data?, Error>
```

The `fetchQuery` method allows you to perform a query without displaying the data in a view. Sometimes this can be useful to update the local store with new data in response to an event, or if you  need access to a query's data in a background task.

If you want to show query data in a SwiftUI view, use the [@Query](query.md) property wrapper.

## Running mutations outside a view

### `commitMutation`

```swift
func commitMutation<Op: Operation>(
  _ operation: Op,
  optimisticResponse: [String: Any]? = nil,
  optimisticUpdater: SelectorStoreUpdater? = nil,
  updater: SelectorStoreUpdater? = nil
) -> AnyPublisher<Op.Data?, Error>
```

The `commitMutation` method allows you to execute a mutation to update data on the server. You can use this if you need to execute a mutation outside your views.

Note that you need to subscribe to the publisher that is returned (using `sink` or `assign`) in order for your mutation to actually execute, and if that subscription is canceled early for some reason, you may not see the updates you expect.

If you want to run a mutation in response to input from a SwiftUI view, use the [@Mutation](mutation.md) property wrapper, which manages this for you and makes it easy to show progress state in your UI while the mutation is running.

For more information about how to use the `updater` and `optimisticUpdater` parameters, see [Updater functions](../knowledge-base/updater-functions.md).
