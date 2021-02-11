---
title: '@RelayEnvironment'
---

The `@RelayEnvironment` property wrapper provides direct access to the current Relay.swift [Environment](environment.md).

Most of the time, you won't need to use this: the other property wrappers access the the current environment in the same way internally.

You may need this in order to pass on the correct environment to a view that won't inherit it normally. A common way this can happen is when presenting a sheet:

```swift
import SwiftUI
import RelaySwiftUI

struct ContentView: View {
    @RelayEnvironment var environment: Relay.Environment

    @State var isPresented: Bool

    var body: some View {
        Text("Some text")
            .sheet(isPresented: $isPresented) {
                MySheet()
                    .relayEnvironment(environment)
            }
    }
}
```

Using this property wrapper requires that another view higher in the tree has used [relayEnvironment()](relay-environment-modifier.md) to set the current environment for the tree. Otherwise, your app will crash.