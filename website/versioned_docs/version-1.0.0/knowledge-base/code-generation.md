---
title: How code generation works
---

Relay.swift is designed to provide a type-safe way to interact with your app's data. To do this, we use the Relay compiler from the official JavaScript Relay framework with a custom plugin to generate Swift code instead of JavaScript.

The types that are generated are based on both your GraphQL schema and any `graphql()` strings found in your Swift source files. Each `query`, `mutation`, and `fragment` in your sources will become a generated `.graphql.swift` file.

Let's look at examples of what Relay.swift will generate in different situations.

## Fragments

```swift
private let todoFragment = graphql("""
fragment ToDoItem_todo on Todo {
    id
    text
    complete
}
""")
```

We'll use the above GraphQL fragment as our example. When the Relay compiler runs, it will find this fragment and generate a file named `ToDoItem_todo.graphql.swift`.

### The fragment type

```swift
struct ToDoItem_todo {
    var fragmentPointer: FragmentPointer

    init(key: ToDoItem_todo_Key) { /* ... */ }

    static var node: ReaderFragment { /* ... */ }
}
```

First, the compiler will generate a struct with the same name as the fragment. You won't generally have to use its properties and methods yourself; they're there to support Relay itself.

This is the type that you will pass to [@Fragment](../api/fragment.md) in your SwiftUI views.

```swift
struct ToDoItem: View {
    @Fragment(ToDoItem_todo.self) var todo

    // ...
}
```

### The Data struct

```swift
extension ToDoItem_todo {
    struct Data: Decodable {
        var id: String
        var text: String
        var complete: Bool
    }
}
```

All fragments must have a corresponding `Data` type, so the compiler generates a structure that matches the shape of your query. If there are nested fields in the fragment, then it will generate nested types under `Data` to represent that data.

The `Data` type (and any nested types) conforms to Swift's `Decodable` protocol. Relay includes a custom `Decoder` implementation specifically for reading your types from the Relay store.

### The Key protocol

```swift
protocol ToDoItem_todo_Key {
    var fragment_ToDoItem_todo: FragmentPointer { get }
}
```

Fragments also get a Key protocol, which is conformed to by any generated types where the fragment is spread. The Key protocol requires that the type includes a field to get a pointer to this fragment's data. The Key is used to pass data between different views while only exposing the right data to each one. Fragment pointers don't actually include the fragment's data. Instead, they have just enough information for Relay to be able to load it in the view that needs it.

## Operations (queries and mutations)

```swift
private let query = graphql("""
query UserToDoListQuery($id: ID!) {
    user(id: $id) {
        id
        ...ToDoList_user
    }
}
""")
```

Again, we'll use an example from the to-do list app. The Relay compiler will generate a file called `UserToDoListQuery.graphql.swift` for this query.

### The operation type

```swift
struct UserToDoListQuery {
    var variables: Variables

    init(variables: Variables) { /* ... */ }

    static var node: ConcreteRequest { /* ... */ }
}
```

Like fragments, operations get a struct with the same name. Instead of being initialized with a key, operations can have variables to parameterize the operation.

### The Variables struct

```swift
extension UserToDoListQuery {
    struct Variables: VariableDataConvertible {
        var id: String

        var variableData: VariableData {
            [
                "id": id,
            ]
        }
    }
}
```

If the operation takes any variables, a `Variables` struct will be generated with the appropriate fields for setting those variables. If it doesn't take any variables, it will instead be a type alias to `EmptyVariables`, which enables some shortcuts when using the operation in Relay.swift.

Variable structs and any `input` types contained in them conform to `VariableDataConvertible`, another Relay.swift protocol, so there's also a field to convert the variables to `VariableData`. `VariableData` is a more type-safe wrapper around a dictionary, and it only supports the types that are valid in GraphQL inputs. This allows us to work with the fields of variables internally in Relay while still having them be `Encodable` when they need to be sent to the network. 

### The Data struct

```swift
extension UserToDoListQuery {
    struct Data: Decodable {
        var user: User_user?

        struct User_user: Decodable, ToDoList_user_Key {
            var id: String
            var fragment_ToDoList_user: FragmentPointer
        }
    }
}
```

Just like fragments, operations get a `Data` struct that is used to read their data from the Relay store. This example shows how nested types are generated when the query includes more than just scalar fields.

These nested types are generated specifically for the query or fragment reading the data because they need to only include the fields that were requested, not everything that's in the schema. It's even possible to alias fields in a query, giving them a name that isn't even in the schema. The types are generated so that they only include fields that are actually expected to be present.

Nested data types have a type name based on both the field's type in the GraphQL schema and the field's name in the query. We can't use just the schema type name here because there may be multiple fields with the same schema type, but with different fields selected. So we need a type per field. We could probably name them just based on the field name, but that feels weird.

In this example, we're spreading the `ToDoList_user` fragment onto the `user` field. We need to be able to pass this user on to the `ToDoList` view, so the `User_user` type also conforms to `ToDoList_user_Key` and includes a `fragment_ToDoList_user` property. This is enough information for the `ToDoList` view to load the data it needs from Relay.swift.

### Unions and Interfaces

TODO

## Enums

```graphql
enum PostStatus {
  DRAFT
  CANCELED
  POSTED
}
```

Enums, and input types as we'll see, are a bit special because they may need to be reusable across multiple operations or fragments, so we generate a type for them in the first file where we need them. Thankfully, Swift doesn't really care which file a type is defined in, so from there we can use it wherever we need it.

```swift
enum PostStatus: String, Decodable, Hashable, VariableValueConvertible, ReadableScalar, CustomStringConvertible {
    case draft = "DRAFT"
    case canceled = "CANCELED"
    case posted = "POSTED"

    var description: String { rawValue }
}
```

GraphQL enums become Swift enums. They always map to strings, and we lowercase them to get a more Swift-y case name.

Generated enums conform to both `VariableValueConvertible` and `ReadableScalar`, which makes them usable in both the `Variables` and `Data` structs mentioned above.

## Input types

```graphql
input ChangeTodoStatusInput {
  complete: Boolean!
  id: ID!
  userId: ID!
  clientMutationId: String
}
```

You might think that we would treat input types similar to nested types inside `Data` structs, but we don't actually want or need to. Because we can't use different subsets of fields from an input type in different places in our app, it's much better to have a single version of an input type and reuse it anywhere it's needed.

```swift
struct ChangeTodoStatusInput: VariableDataConvertible {
    var complete: Bool
    var id: String
    var userId: String
    var clientMutationId: String?

    var variableData: VariableData {
        [
            "complete": complete,
            "id": id,
            "userId": userId,
            "clientMutationId": clientMutationId,
        ]
    }
}
```

Input types end up looking a lot like the `Variables` structs generated for operations, because besides being unattached to a particular operation, they're the same.