---
title: ConnectionHandler
---

```swift
class ConnectionHandler: Handler
```

The `ConnectionHandler` implements the special logic to handle storing fields tagged with the `@connection` directive. These fields are most commonly used with [@PaginationFragment](../API%20Reference%20Relay%20in%20SwiftUI%20e8c792bb5a824ec5a4e988ea6fd2cd88/@PaginationFragment%2004afaa5ab57b4346a7efd4223ec49873.md)s. The default `HandlerProvider` for an environment already includes the `ConnectionHandler`, so for the most part, this works out-of-the-box. 

If you have mutations that want to use `updater` functions to change the lists of edges for your connections, `ConnectionHandler` exposes some methods that will make those operations much easier.

## Using the default handler

```swift
static let default = ConnectionHandler()
```

The default connection handler is available as `ConnectionHandler.default`.

## Getting the connection record

### `getConnection(_:key:filters:)`

```swift
func getConnection(
  _ record: RecordProxy,
  key: String,
  filters: VariableDataConvertible? = nil
) -> RecordProxy?
```

Normally, you would use the `getLinkedField` on a [RecordProxy](record-proxy.md) to get the record for a field, but connections are stored under a special key to correctly handle the way their arguments change as you are paging through the results. To access the connection field, you can traverse to its parent record and then use `getConnection` to get it from the correct key.

#### Parameters

- `record`: The parent record that contains the connection field
- `key`: The `key` that you specified in the `@connection` directive on the field
- `filters`: The non-paging arguments (or filters) for the connection. These keys should have been passed as `filters` in the `@connection` directive on the field.

## Inserting edges into the connection

### `createEdge(_:connection:node:type:)`

```swift
func createEdge(
  _ store: inout RecordSourceProxy,
  connection: RecordProxy,
  node: RecordProxy,
  type edgeType: String
) -> RecordProxy
```

Sometimes you'll have record for a node that you want to add to a connection, but you won't have an edge record for it. You can use `createEdge` to create that record, which you'll later be able to insert into the connection.

This may not always create a new record. If the connection already has an edge for the node, that edge will be returned instead.

#### Parameters

- `store`: The store that you are adding the edge to. This will be passed in as an argument to your updater function.
- `connection`: The record for the connection to add the edge to. Note that this method doesn't update the connection record. Use `getConnection` to get this record.
- `node`: The node that the edge will contain. The `node` field on the returned edge will be this node.
- `edgeType`: The GraphQL type name for the created edge record.

### `insert(connection:edge:before:)`

```swift
func insert(
  connection: inout RecordProxy,
  edge newEdge: RecordProxy,
  before cursor: String?
)
```

Inserts an edge record before a particular edge in the connection, or at the beginning of the list.

#### Parameters

- `connection`: The record for the connection to add the edge to. Use `getConnection` to get this record.
- `newEdge`: The edge record to add to the connection. Use `createEdge` to create this record if your mutation response isn't already returning an edge record.
- `cursor`: The value of the `cursor` field of the edge that should come after this one. Pass `nil` to insert the new edge at the beginning of the list of edges.

### `insert(connection:edge:after:)`

```swift
func insert(
  connection: inout RecordProxy,
  edge newEdge: RecordProxy,
  after cursor: String?
)
```

Inserts an edge record after a particular edge in the connection, or at the end of the list.

#### Parameters

- `connection`: The record for the connection to add the edge to. Use `getConnection` to get this record.
- `newEdge`: The edge record to add to the connection. Use `createEdge` to create this record if your mutation response isn't already returning an edge record.
- `cursor`: The value of the `cursor` field of the edge that should come before this one. Pass `nil` to insert the new edge at the end of the list of edges.

## Deleting edges from the connection

### `delete(connection:nodeID:)`

```swift
func delete(
  connection: inout RecordProxy,
  nodeID: DataID
)
```

Removes any edges from the connection where the edge's node has the given ID.

This doesn't delete the edge or node records from the store, though they may get garbage-collected if they are no longer referenced elsewhere.

#### Parameters

- `connection`: The record for the connection to add the edge to. Use `getConnection` to get this record.
- `nodeID`: The ID of the node whose edge should be removed from the connection.