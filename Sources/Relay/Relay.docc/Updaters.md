# Using updater functions

Use updater functions to customize how Relay's store is updated when performing mutations or client-side updates.

## Overview

Updater functions provide a hook for you to update Relay's local ``Store`` when a mutation completes. You can use this to make arbitrary complex changes to the store without refetching data from the server. This can make your app feel more responsive, especially when paired with optimistic updates.

## Do you need an updater function?

If your mutation only changes some properties of an existing record, you probably don't need an updater. Relay will match records in the mutation's response to the records that already exist in the store and update their fields. If your mutation response includes the fields you expect to change on the record, they'll update in the store and your UI automatically.

For more complex changes that Relay can't infer automatically, you can use an updater function. Some situations where you would want to use an updater function:

- Adding a record to a list
- Deleting a record from a list
- Reordering records in a list
- Any combination of the above

## How do updater functions work?

You provide an updater function with the `updater` or `optimisticUpdater` parameter when committing a mutation. Most of the time, can use the same updater function for both the optimistic and non-optimistic updaters. Updater functions are only run on a successful response; error responses will not run the updater.

When you commit a mutation, a few different actions will happen in order. The exact actions depend on which parameters you provide:

1. If you provide an `optimisticResponse`, then the store will be updated as though it was the real response.
2. If you provide an `optimisticUpdater`, then that function will be called with a proxy to the Relay store.
3. Relay will wait for the response to the mutation from the server.
4. Any changes applied optimistically will be rolled back, so you're starting from a clean slate.
5. If the response is successful:
    1. The store will be updated with the record data from the response.
    2. If you provide an `updater`, then that function will be called with a proxy to the Relay store.

An updater function takes two parameters:

- `store`: a ``RecordSourceSelectorProxy`` that you can use to read and change records in the Relay store.
- `data`: a ``SelectorData`` instance with the response from the mutation. This may be `nil` if the response is missing non-optional data or if you're running an optimistic updater without an optimistic response.

## Example: adding a new edge to a connection

One of the most common reasons to use an updater is to change the contents of a list, often a list of edges in a paging connection. Let's see how we can use an updater to keep a list up-to-date when we add a new item. We'll use the following mutation to create a new to-do item:

```graphql
mutation AddToDoItemMutation($input: AddTodoInput!) {
    addTodo(input: $input) {
        todoEdge {
            node {
                ...ToDoItem_todo
            }
            cursor
        }
    }
}
```

The result of the `addTodo` mutation in our schema includes a `todoEdge` field to return the entire edge for our new to-do item, which will be really convenient for adding it to our list. We use the `ToDoItem_todo` fragment from our view to make sure that we get all the data for the new to-do item that our UI needs to be able to display it.

Because this to-do item will be a new record, the response alone is not enough for Relay to do anything useful. We need to update the list of edges in our connection to include it using an updater. Let's see what that updater would look like:

```swift
private let updater: SelectorStoreUpdater = { store, data in
    let handler = ConnectionHandler.default
    guard
        let user = store.root.getLinkedRecord("user", args: ["id": "me"]),
        var todos = handler.getConnection(user, key: "ToDoList_todos"),
        let edge = store.getRootField("addTodo")?.getLinkedRecord("todoEdge")
    else {
        return
    }

    handler.insert(connection: &todos, edge: edge, before: nil)
}
```

In this updater, we use the ``ConnectionHandler`` methods provided by Relay to help us get the right record for our pagination connection and add an edge to it. We use the `getRootField` method on the ``RecordSourceSelectorProxy`` to traverse to the record in our mutation's response that has the new edge. Once we have the connection record and the new edge, we insert it at the beginning of the list.

Using this updater, when we add a new to-do item, it'll be prepended to the list of to-do items in our app. Our app's user interface will update to reflect this without needing to refetch the list of to-do items from the server. Updaters let us keep our app's local state consistent with the server's state as the user makes changes without unnecessary refetches.
