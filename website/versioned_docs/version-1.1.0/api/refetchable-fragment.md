---
title: "@RefetchableFragment"
---

The `@RefetchableFragment` property wrapper is very similar to a [@Fragment](fragment.md), but it supports refetching the latest data from the server on-demand.

## Example

```swift
import SwiftUI
import RelaySwiftUI

private let itemFragment = graphql("""
fragment ToDoItem_item on Item
  @refetchable(queryName: "ToDoItemRefetchQuery") {
  text
  complete
}
""")

struct ToDoList: View {
    @RefetchableFragment<ToDoItem_item> var item

    var body: some View {
        if let item = item {
            HStack {
                Image(systemName: item.complete ? "checkmark.square" : "square")
                Text("\(item.text)")

                Spacer()

                Button {
                    item.refetch()
                } label: {
                    Image(systemName: "arrow.clockwise.circle.fill")
                }
            }
        }
    }
}
```

## Requirements

The fragment must have a `@refetchable` directive that names a query operation that will be generated to refetch the data for the fragment. Using `@refetchable` requires that the fragment be declared on `Query`, `Viewer`, or a type that implements the `Node` interface. Otherwise, Relay won't know where in the graph to fetch the new data from.

#### Property value

The `@RefetchableFragment` property will be a read-only optional value with the fields the fragment requests. This value will automatically update and re-render the view when the Relay store updates any relevant records, including when the data is refetched.

The property value will also include a function to trigger the refresh:

- `refetch(_ variables: Variables? = nil)`: Function that can be called to trigger a refetch of the fragment's data. `variables` will be the variables for the refetch query that Relay generates for you. This may change which node the fragment is targetting from then on. That's okay: Relay will keep track of that for you, but be aware that it may not match the original fragment your view is passing in.