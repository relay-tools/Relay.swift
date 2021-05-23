---
title: RecordSourceSelectorProxy
---

```swift
protocol RecordSourceSelectorProxy: RecordSourceProxy
```

A `RecordSourceSelectorProxy` provides API for reading from and updating the Relay store in response to a mutation. This proxy is passed to `updater` and `optimisticUpdater` functions you provide with your mutations. It allows you to update the client-side store to reflect the new state after the mutation has been performed.

Relay automatically uses the responses to your mutations to update records in the store with matching IDs, but there are other kinds of state changes that you'd like to reflect in your UI that Relay can't figure out automatically. For example:

- Adding a new record to a list
- Deleting a record
- Moving a record within a list
- Moving a record between different lists

One way to handle these would be to refetch any affected queries. But doing so would make your app less responsive by needing to wait for at least one extra network call, and it may get complicated keeping track of which queries will be affected. Updaters are fast, because they don't perform any extra network calls (you can even do them optimistically before the mutation has responded), and they keep the logic for how to update the state in one place with the mutation itself.

If you're using `@connection` fields for pagination, see [ConnectionHandler](connection-handler.md) for some convenient methods for manipulating those fields.

## Getting records from the store

```swift
var root: RecordProxy { get }
```

The `root` property gives you a [RecordProxy](record-proxy.md) for the root type in your schema (usually `Query` or `Root`). You can use the record proxy to traverse to the parts of your schema that you want to update.

```swift
subscript(_ dataID: DataID) -> RecordProxy? { get }
```

You can provide a specific ID of a record as a subscript to the record source proxy to get a [RecordProxy](record-proxy.md) for that record. If the record is not in the store, this will be `nil`.

```swift
func getRootField(_ fieldName: String) -> RecordProxy?
```

`getRootField` lets you access a singular field from the root of the mutation response.

For example, if I execute this mutation:

```graphql
mutation ChangeTodoStatusMutation($input: ChangeTodoStatusInput!) {
	changeTodoStatus(input: $input) {
		todo {
			id
			complete
		}
	}
}
```

Then I can access the `todo` returned in the response like this:

```swift
func updater(store: inout RecordSourceSelectorProxy, data: SelectorData?) {
	guard
		let changeTodoStatus = store.getRootField("changeTodoStatus"),
		let todo = changeTodoStatus.getLinkedField("todo")
    else {
		return
	}

	// now do things with todo
}
```

Since this is accessing records in the store, you may find that parts of the graph contain more fields than just those requested in the mutation, as the mutation response got merged with existing data in the store.

```swift
func getPluralRootField(_ fieldName: String) -> [RecordProxy?]?
```

`getPluralRootField` lets you access a plural field from the root of the mutation response.

This is just like `getRootField` except it returns an array of records instead of a single record. Use this when the return type of your mutation is a list.

## Updating the store's contents

```swift
mutating func create(dataID: DataID, typeName: String) -> RecordProxy
```

Creates a new empty record in the store.

#### Parameters

- `dataID`: The ID of the new record. If the record type has an `id` field, that value should be used for the `dataID`. Otherwise, you can generate an emphemeral client-local ID by using `.generateClientID()`.
- `typeName`: The name of the type of the record. This should be one of the types defined in your GraphQL schema.

#### Returns

A `RecordProxy` for the newly created record. You can use the proxy to set other fields on the record or to reference it from other records.

```swift
mutating func delete(dataID: DataID)
```

Deletes an existing record from the store.

This won't automatically remove references to the record throughout the store, but Relay gracefully treats missing records as though they were `nil`.

#### Parameters

- `dataID`: The ID of the record to delete.

```swift
func invalidateStore()
```

Marks the entire Relay store as invalid and needing to be refetched.

If the store is invalidated, all of records currently present in the store will still exist, but when a [@Query](query.md) is rendered with a `.storeOrNetwork` or `.storeAndNetwork` fetch policy, those records will not be considered valid and will be ignored, requiring a network request to get the latest data. You can use this to ensure your UI doesn't display data that is known to be stale.