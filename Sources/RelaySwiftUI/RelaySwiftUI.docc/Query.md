# ``RelaySwiftUI/Query``

<!--@START_MENU_TOKEN@-->Summary<!--@END_MENU_TOKEN@-->

## Example

```swift
private let query = graphql("""
query ToDoListQuery {
    list(id: "abc") {
        items {
            text
        }
    }
}
""")

struct ToDoList: View {
    @Query<ToDoListQuery> var query

    var body: some View {
        switch query.get() {
            case .loading:
                Text("Loading...")
            case .failure(let error):
                Text("Error: \(error.localizedDescription)")
            case .success(let data):
                List(data?.list?.items ?? [], id: \.id) { toDoItem in
                    Text("\(toDoItem.text)")
                }
        }
    }
}
```

## Topics

### Creating a Query

- ``init(fetchPolicy:)``

### Getting data from a query

- ``wrappedValue-swift.property``
- ``WrappedValue-swift.struct``
- ``Result``
