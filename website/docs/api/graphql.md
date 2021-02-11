---
title: GraphQL tagged strings
---

```swift
func graphql(_ query: String) -> TaggedGraphQLQuery
```

The `graphql` function is used to tag GraphQL strings in your application.

When you run the Relay compiler, it will scan your source code for multiline string literals wrapped in the `graphql` function, and it will use those queries and fragments to perform [How code generation works](../Knowledge%20Base%20472752960b6b4afe854e4b3a814bbb54/How%20code%20generation%20works%2001f4b2f7a83343739312db8313abe53c.md).

Your GraphQL strings should be assigned to private constants (`private let foo = ...`) in the source file that uses the query or fragment. There are some conventions for naming the constant:

- Queries: `query`.
- Mutations: `mutation`.
- Fragments: `<paramName>Fragment`. For instance, if your view takes a `todo` parameter that is a fragment, call the GraphQL string constant `todoFragment`.

The result of the `graphql` function is not directly used. When using Relay in JavaScript, you write your GraphQL code directly in places where you would reference your query or fragment type, and a Babel plugin replaces it with an import of the code the Relay compiler generates. Swift doesn't have anything like Babel for doing arbitrary transforms at build time, so we have to be a little more indirect.