---
title: relayEnvironment()
---

```swift
extension View {
    func relayEnvironment(_ environment: Relay.Environment) -> some View
}
```

The `relayEnvironment` view modifier gives a view and all of its children access to a Relay.swift [Environment](environment.md).

Without this, none of the `RelaySwiftUI` property wrappers will work, and your app will crash when it tries to use Relay. You will usually want to use this as high as possible in your view tree so that all of the views in your app can access Relay.

## Example

You can create your Relay Environment in your app's `SceneDelegate` and attach it to your root view.

```swift
import UIKit
import SwiftUI
import Relay
import RelaySwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

		let environment = Relay.Environment(network: MyNetwork(), store: Store())

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {

        let contentView = ContentView()
            .relayEnvironment(environment)

        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window
            window.makeKeyAndVisible()
        }
    }
}
```

Or if you're using the `App` protocol for your `@main` entrypoint, you might store your environment in a `@State` variable.

```swift
import SwiftUI
import Relay
import RelaySwiftUI

@main
struct MyApp: App {
	@State var environment = Relay.Environment(network: MyNetwork(), store: Store())

	var body: some Scene {
		WindowGroup {
			ContentView()
				.relayEnvironment(environment)
		}
	}
}
```