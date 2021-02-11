---
title: RecordProxy
---

```swift
protocol RecordProxy
```

A `RecordProxy` provides API reading and updating the fields of a particular record in the Relay store. A `RecordProxy` can be obtained from a [RecordSourceSelectorProxy](record-source-selector-proxy.md) or another `RecordProxy` when updating the store after a mutation.

## Reading record metadata

### `dataID`

```swift
var dataID: DataID { get }
```

Returns the ID of the record.

All records have a unique ID in the store. If the record has an `id` field, that value will be used as the ID. Otherwise, Relay will choose a client-side ID and use that.

Because Relay uses that `id` field as a store-wide ID, it's important that you don't use the same IDs for two different values of different types. Your IDs must be globally unique, not just unique within a particular type. One way to do this is to include the type name or an abbreviation of it as part of the ID.

### `typeName`

```swift
var typeName: String { get }
```

Returns the name of the schema type for the record.

Every record in the store belongs to one of the types defined in your GraphQL schema.

## Accessing fields from a record

### `subscript(_:args:)`

```swift
subscript(
  _ name: String,
  args args: VariableDataConvertible? = nil
) -> Any? { get set }
```

You can use subscripts to read and write scalar fields of a record.

If the field has arguments, those should be passed to the subscript as well. This can be an ordinary Swift dictionary:

```swift
record["name", args: ["language": "en"]] = "hello world"
```

## Accessing linked records

### `getLinkedRecord(_:args:)` & `setLinkedRecord(_:args:record:)`

```swift
func getLinkedRecord(
  _ name: String,
  args: VariableDataConvertible? = nil
) -> RecordProxy?

mutating func setLinkedRecord(
  _ name: String,
  args: VariableDataConvertible? = nil,
  record: RecordProxy
)
```

To read and write fields where the value is another record, use `getLinkedRecord` and `setLinkedRecord`. Like scalar field subscripts, they take an options `args` parameter for any arguments passed to the field.

Note that `setLinkedRecord` takes a non-optional record parameter. If you want to set a field for a linked record to `nil`, use the subscript like you would a scalar field.

### `getOrCreateLinkedRecord(_:typeName:args:)`

```swift
mutating func getOrCreateLinkedRecord(
  _ name: String,
  typeName: String,
  args: VariableDataConvertible?
) -> RecordProxy
```

A convenience function is available to "upsert" a record for a linked field. `getOrCreateLinkedRecord` will use an existing record for the field if one is already present, or it will create an empty one if there isn't one set.

If a record is created, it will have a client-side ID chosen for it by Relay. If you need the ID to be something specific, use the `create` method on [RecordSourceSelectorProxy](record-source-selector-proxy.md) to create the record, then call `setLinkedRecord` to set the value for the field.

## Accessing lists of linked records

### `getLinkedRecords(_:args:)` & `setLinkedRecords(_:args:records:)`

```swift
func getLinkedRecords(
  _ name: String,
  args: VariableDataConvertible?
) -> [RecordProxy?]?

mutating func setLinkedRecords(
  _ name: String,
  args: VariableDataConvertible?,
  records: [RecordProxy?]
)
```

To read and write fields where the value is a list of records, use `getLinkedRecords` and `setLinkedRecords`. These behave very similarly to their singular equivalents.

## Copying between records

### `copyFields(from:)`

```swift
mutating func copyFields(from record: RecordProxy)
```

Copies all of the fields from `record` into `self`.

Any fields not present in `record` will be unchanged in `self`.

Note that this copies all fields, including linked records.

## Invalidation

### `invalidateRecord()`

```swift
mutating func invalidateRecord()
```

Marks the record as having invalid data that needs to be refreshed.

If a record is invalidated, it will still exist in the store, but when a [@Query](query.md) is rendered with a `.storeOrNetwork` or `.storeAndNetwork` fetch policy, those records will not be considered valid and will be ignored, requiring a network request to get the latest data. You can use this to ensure your UI doesn't display data that is known to be stale.