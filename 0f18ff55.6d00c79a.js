(window.webpackJsonp=window.webpackJsonp||[]).push([[7],{122:function(e,n,t){"use strict";t.d(n,"a",(function(){return m})),t.d(n,"b",(function(){return w}));var r=t(0),o=t.n(r);function i(e,n,t){return n in e?Object.defineProperty(e,n,{value:t,enumerable:!0,configurable:!0,writable:!0}):e[n]=t,e}function a(e,n){var t=Object.keys(e);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);n&&(r=r.filter((function(n){return Object.getOwnPropertyDescriptor(e,n).enumerable}))),t.push.apply(t,r)}return t}function l(e){for(var n=1;n<arguments.length;n++){var t=null!=arguments[n]?arguments[n]:{};n%2?a(Object(t),!0).forEach((function(n){i(e,n,t[n])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(t)):a(Object(t)).forEach((function(n){Object.defineProperty(e,n,Object.getOwnPropertyDescriptor(t,n))}))}return e}function c(e,n){if(null==e)return{};var t,r,o=function(e,n){if(null==e)return{};var t,r,o={},i=Object.keys(e);for(r=0;r<i.length;r++)t=i[r],n.indexOf(t)>=0||(o[t]=e[t]);return o}(e,n);if(Object.getOwnPropertySymbols){var i=Object.getOwnPropertySymbols(e);for(r=0;r<i.length;r++)t=i[r],n.indexOf(t)>=0||Object.prototype.propertyIsEnumerable.call(e,t)&&(o[t]=e[t])}return o}var p=o.a.createContext({}),s=function(e){var n=o.a.useContext(p),t=n;return e&&(t="function"==typeof e?e(n):l(l({},n),e)),t},m=function(e){var n=s(e.components);return o.a.createElement(p.Provider,{value:n},e.children)},u={inlineCode:"code",wrapper:function(e){var n=e.children;return o.a.createElement(o.a.Fragment,{},n)}},y=o.a.forwardRef((function(e,n){var t=e.components,r=e.mdxType,i=e.originalType,a=e.parentName,p=c(e,["components","mdxType","originalType","parentName"]),m=s(t),y=r,w=m["".concat(a,".").concat(y)]||m[y]||u[y]||i;return t?o.a.createElement(w,l(l({ref:n},p),{},{components:t})):o.a.createElement(w,l({ref:n},p))}));function w(e,n){var t=arguments,r=n&&n.mdxType;if("string"==typeof e||r){var i=t.length,a=new Array(i);a[0]=y;var l={};for(var c in n)hasOwnProperty.call(n,c)&&(l[c]=n[c]);l.originalType=e,l.mdxType="string"==typeof e?e:r,a[1]=l;for(var p=2;p<i;p++)a[p]=t[p];return o.a.createElement.apply(null,a)}return o.a.createElement.apply(null,t)}y.displayName="MDXCreateElement"},70:function(e,n,t){"use strict";t.r(n),t.d(n,"frontMatter",(function(){return a})),t.d(n,"metadata",(function(){return l})),t.d(n,"toc",(function(){return c})),t.d(n,"default",(function(){return s}));var r=t(3),o=t(7),i=(t(0),t(122)),a={title:"relayEnvironment()"},l={unversionedId:"api/relay-environment-modifier",id:"api/relay-environment-modifier",isDocsHomePage:!1,title:"relayEnvironment()",description:"`swift",source:"@site/docs/api/relay-environment-modifier.md",slug:"/api/relay-environment-modifier",permalink:"/Relay.swift/docs/api/relay-environment-modifier",editUrl:"https://github.com/relay-tools/Relay.swift/edit/main/website/docs/api/relay-environment-modifier.md",version:"current",sidebar:"docs",previous:{title:"Introduction",permalink:"/Relay.swift/docs/api/intro-relay-swift-ui"},next:{title:"@RelayEnvironment",permalink:"/Relay.swift/docs/api/relay-environment-wrapper"}},c=[{value:"Example",id:"example",children:[]}],p={toc:c};function s(e){var n=e.components,t=Object(o.a)(e,["components"]);return Object(i.b)("wrapper",Object(r.a)({},p,t,{components:n,mdxType:"MDXLayout"}),Object(i.b)("pre",null,Object(i.b)("code",{parentName:"pre",className:"language-swift"},"extension View {\n    func relayEnvironment(_ environment: Relay.Environment) -> some View\n}\n")),Object(i.b)("p",null,"The ",Object(i.b)("inlineCode",{parentName:"p"},"relayEnvironment")," view modifier gives a view and all of its children access to a Relay.swift ",Object(i.b)("a",{parentName:"p",href:"/Relay.swift/docs/api/environment"},"Environment"),"."),Object(i.b)("p",null,"Without this, none of the ",Object(i.b)("inlineCode",{parentName:"p"},"RelaySwiftUI")," property wrappers will work, and your app will crash when it tries to use Relay. You will usually want to use this as high as possible in your view tree so that all of the views in your app can access Relay."),Object(i.b)("h2",{id:"example"},"Example"),Object(i.b)("p",null,"You can create your Relay Environment in your app's ",Object(i.b)("inlineCode",{parentName:"p"},"SceneDelegate")," and attach it to your root view."),Object(i.b)("pre",null,Object(i.b)("code",{parentName:"pre",className:"language-swift"},"import UIKit\nimport SwiftUI\nimport Relay\nimport RelaySwiftUI\n\nclass SceneDelegate: UIResponder, UIWindowSceneDelegate {\n    var window: UIWindow?\n\n        let environment = Relay.Environment(network: MyNetwork(), store: Store())\n\n    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {\n\n        let contentView = ContentView()\n            .relayEnvironment(environment)\n\n        if let windowScene = scene as? UIWindowScene {\n            let window = UIWindow(windowScene: windowScene)\n            window.rootViewController = UIHostingController(rootView: contentView)\n            self.window = window\n            window.makeKeyAndVisible()\n        }\n    }\n}\n")),Object(i.b)("p",null,"Or if you're using the ",Object(i.b)("inlineCode",{parentName:"p"},"App")," protocol for your ",Object(i.b)("inlineCode",{parentName:"p"},"@main")," entrypoint, you might store your environment in a ",Object(i.b)("inlineCode",{parentName:"p"},"@State")," variable."),Object(i.b)("pre",null,Object(i.b)("code",{parentName:"pre",className:"language-swift"},"import SwiftUI\nimport Relay\nimport RelaySwiftUI\n\n@main\nstruct MyApp: App {\n    @State var environment = Relay.Environment(network: MyNetwork(), store: Store())\n\n    var body: some Scene {\n        WindowGroup {\n            ContentView()\n                .relayEnvironment(environment)\n        }\n    }\n}\n")))}s.isMDXComponent=!0}}]);