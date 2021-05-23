---
title: QueryPreview
---

```swift
struct QueryPreview<Operation: Relay.Operation, Content: View>: View
```

A `QueryPreview` is a view that makes it easier to create SwiftUI previews for views that use [@Fragment](fragment.md) or [@PaginationFragment](pagination-fragment.md) to load their data.

All data loaded by Relay needs to orignally come from a query, which can make it tricky to preview leaf fragment views in isolation from the rest of your app. You can define a new query specifically for your preview and provide data for it using [previewPayload()](preview-payload.mdx), but then you still need a view that fetches the query's data using [@Query](query.md).

You can use `QueryPreview` for that rather than defining a new View type.

```swift
struct ToDoItem_Previews: PreviewProvider {
    static let op = ToDoItemPreviewQuery()

    static var previews: some View {
        QueryPreview(op) { data in
            List(data.user!.todos!) { todoItem in
                ToDoItem(todo: todoItem)
            }
        }
        .previewPayload(op, resource: "ToDoItemPreview")
    }
}
```

`QueryPreview` handles the loading, error, and missing data cases for the query by showing a `Text` view with information about them, because unless you've made a mistake, these cases shouldn't happen for previews. If the query is able to load its data, the data will be passed on to you to render your preview. This is a handy shortcut to render one or more fragment views in a preview using the results of a query.

See the documentation for [previewPayload()](preview-payload.mdx) for a more complete example of how to use this.

## Creating a QueryPreview
 
### `init(_:_:)`

```swift
init(
    _ operation: Operation,
    _ content: @escaping (Operation.Data) -> Content
)
```

Creates a new `QueryPreview` for a given query operation.

#### Parameters

- `operation`: The query that the view should load.
- `content`: The view that should be rendered if the query is able to successfully load its data.