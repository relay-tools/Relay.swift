---
title: Making changes with mutations
hide_table_of_contents: true
---

So far, all our app has done is display existing data. Most interesting apps also let you change data. In GraphQL, this is supported by using mutations. Our to-do list app's schema includes several mutations for working with to-do items, and we can use these to add some interactivity to our app.

Our to-do items have checkboxes but right now, tapping them doesn't do anything. Let's fix that using the `changeTodoStatus` mutation. Mutations don't belong to a single view, let's create a new file just for this mutation called `ChangeTodoStatus.swift`.

```swift
import Relay

private let mutation = graphql("""
mutation ChangeTodoStatusMutation($input: ChangeTodoStatusInput!) {
    changeTodoStatus(input: $input) {
        todo {
            id
            complete
        }
    }
}
""")
```

In GraphQL, mutations can return data just like queries can. Relay.swift will use this data to update the data in its local store. Knowing this, we make our mutation return the `complete` field on the to-do item we're changing, since we expect this mutation to change its value and we want our UI to update accordingly.

When we run `npx relay-compiler`, a `__generated__/ChangeTodoStatusMutation.graphql.swift` file is generate. We can add that file to our project and then start using this mutation in one of our views.

Let's go back to our `ToDoItem` view and turn our checkbox into a button that uses the mutation.

```swift
import SwiftUI
import RelaySwiftUI

private let todoFragment = graphql("""
fragment ToDoItem_todo on Todo {
    id
    text
    complete
}
""")

struct ToDoItem: View {
    @Fragment<ToDoItem_todo> var todo

    @Mutation<ChangeTodoStatusMutation> var changeStatus

    var body: some View {
        if let todo = todo {
            HStack {
                Button {
                    changeStatus.commit(variables: .init(input: .init(
                        complete: !todo.complete,
                        id: id,
                        userId: "me"
                    )))
                } label: {
                    Image(systemName: todo.complete ? "checkmark.square" : "square")
                }
                .buttonStyle(BorderlessButtonStyle())
                .disabled(changeStatus.isInFlight)

                Text(verbatim: todo.text)
            }
        }
    }
}
```

To use our new mutation in a SwiftUI view, we add a [@Mutation](../api/mutation.md) property for it. This property has a `commit` function and an `isInFlight` property. We use the `commit` function in the action of our new Button to perform the mutation. Until the server responds to us, the `isInFlight` property will be `true`. We use that to disable the button, both to indicate to the user that something is happening and to prevent redundant requests to the server.

Once the server performs our mutation and responds to our request, Relay.swift will use the `id` and `complete` fields in the response to update the data in its local store. When this happens, we'll see the checkbox for our to-do item toggle automatically without us having to trigger an update. This works because [@Query](../api/query.md) and [@Fragment](../api/fragment.md) properties automatically subscribe to changes to their data, so whenever some data they're responsible for displaying changes in the store, they will re-render their view.

Because of how our input types are structured, our button's action callback is a little noisy. We can hide some of this complexity outside our view code behind a cleaner API. Let's add an extension to `ChangeTodoStatus.swift` to provide a cleaner commit function for this mutation:

```swift
import Relay
import RelaySwiftUI

private let mutation = graphql("""
mutation ChangeTodoStatusMutation($input: ChangeTodoStatusInput!) {
    changeTodoStatus(input: $input) {
        todo {
            id
            complete
        }
    }
}
""")

extension Mutation.Mutator where Operation == ChangeTodoStatusMutation {
    func commit(id: String, complete: Bool) {
        commit(
            variables: .init(input: .init(
                complete: complete,
                id: id,
                userId: "me"
            ))
        )
    }
}
```

`Mutation.Mutator` is the type returned by a [@Mutation](../api/mutation.md) property. We're adding a special `commit` function to this type specifically when the operation is a `ChangeTodoStatusMutation`. Now we can make our button action easier to read.

```swift
Button {
    changeStatus.commit(
        id: todo.id,
        complete: !todo.complete
    )
} label: {
    Image(systemName: todo.complete ? "checkmark.square" : "square")
}
.buttonStyle(BorderlessButtonStyle())
.disabled(changeStatus.isInFlight)
```

Now it's much clearer what's happening.

## Optimistic updates for immediate feedback

Right now, the checkbox is only updating once the server responds. On a slow connection, this could take several seconds, during which our user might feel confused about why the state hasn't changed.

We can't fix their connection speed, but we can make our app feel more responsive by assuming the mutation will succeed and updating the app state accordingly. This is called an optimistic update, and it's a great way to improve the experience of using your app.

In Relay, an optimistic update works by taking a snapshot of the local store and then applying the change. This causes the app UI to immediately update. When the real response comes in, the optimistic update is rolled back, and the real response is handled instead. Ideally, the outcome is the same, but if the real response is an error, the rollback ensures you don't keep showing incorrect data.

Let's update our mutation to use an optimistic response:

```swift
import Relay
import RelaySwiftUI

private let mutation = graphql("""
mutation ChangeTodoStatusMutation($input: ChangeTodoStatusInput!) {
    changeTodoStatus(input: $input) {
        todo {
            id
            complete
        }
    }
}
""")

extension Mutation.Mutator where Operation == ChangeTodoStatusMutation {
    func commit(id: String, complete: Bool) {
        commit(
            variables: .init(input: .init(
                complete: complete,
                id: id,
                userId: "me"
            )),
            optimisticResponse: [
                "changeTodoStatus": [
                    "todo": [
                        "id": id,
                        "complete": complete,
                    ]
                ]
            ]
        )
    }
}
```

Our special commit function is coming in handy again. We've added an `optimisticResponse` parameter to our commit call. This value is a dictionary that should match what the `data` property in the actual GraphQL response is expected to contain. It should match the structure of the mutation itself, as this one does.

Now when we tap our checkbox button, our UI will update immediately, and as long as our request succeeds, we'll never notice that it wasn't already done.

---

That's all for this guide. We've covered the basics of using Relay.swift to build SwiftUI apps, which will get you pretty far. You can find more detailed information in our API docs:

- [API Reference: Relay.swift](../api/intro-relay.md)
- [API Reference: Relay in SwiftUI](../api/intro-relay-swift-ui.md)