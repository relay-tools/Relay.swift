---
title: Store
---

```swift
class Store
```

The `Store` keeps a local copy of records that your queries have fetched.

## Creating a store

### `init(source:)`

```swift
init(source: RecordSource = DefaultRecordSource())
```

You can create a new store by providing a record source. Usually the default empty record source is fine, but you could pass in a pre-populated one if you were loading records from an on-disk cache, for instance.

You'll usually create a store as part of creating your app's [Environment](environment.md).

We may document `Store`'s public methods at some point, but they're largely there to implement higher-level APIs like `RelaySwiftUI`. Most applications don't have to interact with a store directly beyond creating it.