---
title: Declarative mutation directives
---

In version [10.1.0](https://github.com/facebook/relay/releases/tag/v10.1.0), Relay added support for declarative mutation directives in both the compiler and the JavaScript library. Relay.swift also supports these directives, which can remove the need to write [updater functions](updater-functions.md) for your mutations for some common cases of adding and removing records.

## Adding nodes to a connection

Relay supports four directives for adding to the list of records managed by a `@connection`:

- `@prependNode`
- `@appendNode`
- `@prependEdge`
- `@appendEdge`

Let's look at an example of how to use `@prependNode`:

```graphql
mutation AddTodoMutation($input: AddTodoInput!, $connections: [ID!]!) {
	addTodo(input: $input) {
		todo @prependNode(connections: $connections, edgeTypeName: "TodoEdge") {
			id
			text
			complete
		}
	}
}
```

When we execute this mutation, we want the new `Todo` item to be inserted at the top of our list of todos. Normally, we would need to write an updater function to do this using [ConnectionHandler](../api/connection-handler.md) methods and pass that function when we commit the mutation, but by marking the node in our mutation result with `@prependNode`, Relay do this automatically. Relay will automatically create a new edge record using the `edgeTypeName` we passed to the directive, and will set the `node` field of that record to the `todo` returned in the mutation's response. Then it will add that edge to the beginning of the list of edges for the connection. Any views that are showing that connection will update to show the new item.

`@appendNode` works just like `@prependNode`, but it adds the new item to the end of this list rather than the beginning.

Relay still needs to know which connection(s) to add the node to, so we pass those in to the directive with the `$connections` variable that we added to the mutation. The strings we pass in need to be the record IDs for each connection, not the `key` passed to the `@connection` directive. This is because a connection may support filter arguments, which cause one key to be used to store multiple records with different filtered versions of the same connection. Relay needs to know exactly which one(s) you want to update. See [further below](#getting-the-record-id-for-a-connection) for how you can determine the record ID for your connections.

### Returning edges instead of nodes

If the mutation's response payload includes an edge record instead of just a node, we can use `@prependEdge` or `@appendEdge` instead:

```graphql
mutation AddTodoMutation($input: AddTodoInput!, $connections: [ID!]!) {
	addTodo(input: $input) {
		todoEdge @prependEdge(connections: $connections) {
			cursor
			node {
				id
				text
				complete
			}
		}
	}
}
```

When using the edge variants of these directives, we don't have to pass an `edgeTypeName`, since Relay doesn't have to build the edge itself: the record already exists in the mutation's response.

## Deleting nodes from a connection

The `@deleteEdge` directive will remove the edge(s) corresponding to a particular node from one or more connections.

```graphql
mutation RemoveTodoMutation($input: RemoveTodoInput!, $connections: [ID!]!) {
	removeTodo(input: $input) {
		deletedTodoID @deleteEdge(connections: $connections)
	}
}
```

To use this directive, your mutation response must have a field corresponding to the ID of the node whose edge(s) you want to remove. If there are multiple edges in the connection for that node, all of them will be removed. The record itself remains in the store, so if it is referenced from other places, those references will continue to be valid.

As with the append and prepend directives, this directive needs the record IDs of the connections it should update. [See further below](#getting-the-record-id-for-a-connection) for how you can determine the record ID for your connections.

## Deleting records from the store

The `@deleteRecord` will remove a record entirely from Relay's store.

```graphql
mutation RemoveTodoMutation($input: RemoveTodoInput!) {
	removeTodo(input: $input) {
		deletedTodoID @deleteRecord
	}
}
```

Similar to `@deleteEdge`, this directive is used on a field in your mutation response with the ID of the record to delete. Unlike `@deleteEdge`, `@deleteRecord` doesn't remove any references to the record: it just deletes it. This can cause fragments to be missing data that they previously weren't, so use this with care.

## Getting the record ID for a connection

There are two ways to get a record ID that we can pass in to the `$connections` argument of our mutation. The preferred way is to ask for it in your query or fragment, and then pass it on to the mutation when you commit. The record ID for any record is available with the `__id` field.

```graphql
fragment ToDoList_user on User
  @refetchable(queryName: "ToDoListPaginationQuery")
  @argumentDefinitions(
    count: { type: "Int", defaultValue: 100 }
    cursor: { type: "String" }
	) {
  todos(first: $count, after: $cursor)
	  @connection(key: "ToDoList_todos") {
	  __id
    edges {
      node {
        id
        ...ToDoItem_todo
      }
    }
  }
}
```

The `__id` field is similar to `__typename` in that it doesn't need to be declared in your schema and is available as a selection anywhere in the graph. It will always return the ID Relay is using for the corresponding record in its store. You can then pass that ID as the connections when committing the mutation to add the item:

```swift
addTodo.commit(
	variables: .init(
		input: AddTodoInput(/* ... */),
		connections: [user.todos.__id]
	)
)
```

This works well when you need to perform the mutation from the same view or a subview of the one that is using the connection, as there's a direct way to pass the ID of the connection to the code that commits the mutation. In some cases, you may need to perform the mutation from a completely different part of your app from where you are viewing the data in the connection. For these situations, you can use the `getConnectionID(parentID:key:filters:)` method on [ConnectionHandler](../api/connection-handler.md) to ask Relay directly for the ID of a particular connection record.

```swift
addTodo.commit(
	variables: .init(
		input: AddTodoInput(/* ... */),
		connections: [
			ConnectionHandler.default.getConnectionID(
				parentID: DataID(user.id),
				key: "ToDoList_todos"
			)
		]
	)
)
```

To use `getConnectionID`, you need to know the record ID for the parent record of the connection, as well as the key of the connection and any filter arguments if necessary. In this example, the connection is on a field of the `User` type, which implements `Node` so its record ID matches its `id` field. Some other common parent IDs for connections are:

- `DataID.rootID`: for connections on fields on the root `Query` type of the schema
- `DataID.viewerID`: for connections on fields on the `Viewer` type

If your connection is not on the `Query`, `Viewer`, or a `Node`, it won't have a stable ID and you'll need to fetch it from a query or fragment using the `__id` field. But you would be better off changing your schema instead, since in this case it also won't be usable with [@PaginationFragment](../api/pagination-fragment.md), which has similar constraints.