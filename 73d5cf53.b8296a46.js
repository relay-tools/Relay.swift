(window.webpackJsonp=window.webpackJsonp||[]).push([[34],{122:function(e,t,n){"use strict";n.d(t,"a",(function(){return p})),n.d(t,"b",(function(){return f}));var r=n(0),o=n.n(r);function a(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function i(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);t&&(r=r.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,r)}return n}function l(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?i(Object(n),!0).forEach((function(t){a(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):i(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function c(e,t){if(null==e)return{};var n,r,o=function(e,t){if(null==e)return{};var n,r,o={},a=Object.keys(e);for(r=0;r<a.length;r++)n=a[r],t.indexOf(n)>=0||(o[n]=e[n]);return o}(e,t);if(Object.getOwnPropertySymbols){var a=Object.getOwnPropertySymbols(e);for(r=0;r<a.length;r++)n=a[r],t.indexOf(n)>=0||Object.prototype.propertyIsEnumerable.call(e,n)&&(o[n]=e[n])}return o}var s=o.a.createContext({}),u=function(e){var t=o.a.useContext(s),n=t;return e&&(n="function"==typeof e?e(t):l(l({},t),e)),n},p=function(e){var t=u(e.components);return o.a.createElement(s.Provider,{value:t},e.children)},d={inlineCode:"code",wrapper:function(e){var t=e.children;return o.a.createElement(o.a.Fragment,{},t)}},m=o.a.forwardRef((function(e,t){var n=e.components,r=e.mdxType,a=e.originalType,i=e.parentName,s=c(e,["components","mdxType","originalType","parentName"]),p=u(n),m=r,f=p["".concat(i,".").concat(m)]||p[m]||d[m]||a;return n?o.a.createElement(f,l(l({ref:t},s),{},{components:n})):o.a.createElement(f,l({ref:t},s))}));function f(e,t){var n=arguments,r=t&&t.mdxType;if("string"==typeof e||r){var a=n.length,i=new Array(a);i[0]=m;var l={};for(var c in t)hasOwnProperty.call(t,c)&&(l[c]=t[c]);l.originalType=e,l.mdxType="string"==typeof e?e:r,i[1]=l;for(var s=2;s<a;s++)i[s]=n[s];return o.a.createElement.apply(null,i)}return o.a.createElement.apply(null,n)}m.displayName="MDXCreateElement"},125:function(e,t,n){"use strict";n.d(t,"b",(function(){return a})),n.d(t,"a",(function(){return i}));var r=n(21),o=n(126);function a(){var e=Object(r.default)().siteConfig,t=(e=void 0===e?{}:e).baseUrl,n=void 0===t?"/":t,a=e.url;return{withBaseUrl:function(e,t){return function(e,t,n,r){var a=void 0===r?{}:r,i=a.forcePrependBaseUrl,l=void 0!==i&&i,c=a.absolute,s=void 0!==c&&c;if(!n)return n;if(n.startsWith("#"))return n;if(Object(o.b)(n))return n;if(l)return t+n;var u=n.startsWith(t)?n:t+n.replace(/^\//,"");return s?e+u:u}(a,n,e,t)}}}function i(e,t){return void 0===t&&(t={}),(0,a().withBaseUrl)(e,t)}},126:function(e,t,n){"use strict";function r(e){return!0===/^(\w*:|\/\/)/.test(e)}function o(e){return void 0!==e&&!r(e)}n.d(t,"b",(function(){return r})),n.d(t,"a",(function(){return o}))},99:function(e,t,n){"use strict";n.r(t),n.d(t,"frontMatter",(function(){return l})),n.d(t,"metadata",(function(){return c})),n.d(t,"toc",(function(){return s})),n.d(t,"default",(function(){return p}));var r=n(3),o=n(7),a=(n(0),n(122)),i=n(125),l={title:"The Relay environment",hide_table_of_contents:!0},c={unversionedId:"getting-started/relay-environment",id:"getting-started/relay-environment",isDocsHomePage:!1,title:"The Relay environment",description:"Before we can start performing queries to fetch data, we need to create a Relay Environment. At a minimum, the environment is responsible for performing network requests and caching fetched data in a client-side store.",source:"@site/docs/getting-started/relay-environment.mdx",slug:"/getting-started/relay-environment",permalink:"/Relay.swift/docs/getting-started/relay-environment",editUrl:"https://github.com/relay-tools/Relay.swift/edit/main/website/docs/getting-started/relay-environment.mdx",version:"current",sidebar:"docs",previous:{title:"Installation",permalink:"/Relay.swift/docs/getting-started/installation"},next:{title:"Fetching data with queries",permalink:"/Relay.swift/docs/getting-started/fetching-data"}},s=[],u={toc:s};function p(e){var t=e.components,n=Object(o.a)(e,["components"]);return Object(a.b)("wrapper",Object(r.a)({},u,n,{components:t,mdxType:"MDXLayout"}),Object(a.b)("p",null,"Before we can start performing queries to fetch data, we need to create a Relay Environment. At a minimum, the environment is responsible for performing network requests and caching fetched data in a client-side store."),Object(a.b)("p",null,"Relay.swift leaves the specifics of how to connect to your GraphQL API up to you. When you create a new environment, you must provide a network layer by implementing the ",Object(a.b)("inlineCode",{parentName:"p"},"Network")," protocol. Relay will ask your ",Object(a.b)("inlineCode",{parentName:"p"},"Network")," to execute a query against your server and return the resulting JSON data. Here's the network layer for our to-do list app."),Object(a.b)("pre",null,Object(a.b)("code",{parentName:"pre",className:"language-swift"},'import Combine\nimport Foundation\nimport Relay\n\nprivate let graphqlURL = URL(string: "http://localhost:3000/graphql")!\n\nstruct RequestPayload: Encodable {\n    var query: String\n    var operationName: String\n    var variables: VariableData\n}\n\nclass Network: Relay.Network {\n    func execute(\n        request: RequestParameters,\n        variables: VariableData,\n        cacheConfig: CacheConfig\n    ) -> AnyPublisher<Data, Error> {\n        var req = URLRequest(url: graphqlURL)\n        req.setValue("application/json", forHTTPHeaderField: "Content-Type")\n        req.httpMethod = "POST"\n\n        do {\n            let payload = RequestPayload(\n                query: request.text!,\n                operationName: request.name,\n                variables: variables)\n            req.httpBody = try JSONEncoder().encode(payload)\n        } catch {\n            return Fail(error: error).eraseToAnyPublisher()\n        }\n\n        return URLSession.shared.dataTaskPublisher(for: req)\n            .map { $0.data }\n            .mapError { $0 as Error }\n            .eraseToAnyPublisher()\n    }\n}\n')),Object(a.b)("p",null,"The ",Object(a.b)("inlineCode",{parentName:"p"},"execute")," method on a ",Object(a.b)("inlineCode",{parentName:"p"},"Network")," returns an ",Object(a.b)("inlineCode",{parentName:"p"},"AnyPublisher<Data, Error>"),", so there's a lot of options for how you get data from your API into Relay."),Object(a.b)("p",null,"Our network layer for this example will use a GraphQL server we run on our Mac, so it'll only work on the simulator, but that's okay. In order for this to work, though, we need to allow local connections in our app's Info.plist."),Object(a.b)("img",{alt:"Allowing local networking in Info.plist",src:Object(i.a)("img/getting-started/allow-local-networking.png")}),Object(a.b)("p",null,"To get our server running, we need to clone Relay's todo example and start it:"),Object(a.b)("pre",null,Object(a.b)("code",{parentName:"pre"},"$ git clone https://github.com/relayjs/relay-examples\n$ cd relay-examples/todo\n$ yarn\n$ yarn start\n")),Object(a.b)("p",null,"Once you've defined the network layer, you can create an environment with that network layer and an empty store for cached data:"),Object(a.b)("pre",null,Object(a.b)("code",{parentName:"pre",className:"language-swift"},"import Relay\n\nlet environment = Environment(\n    network: Network(),\n    store: Store()\n)\n")),Object(a.b)("p",null,"You'll want to reuse the same environment across the various views in your app. For a SwiftUI app, you should include it in the SwiftUI environment near the top of your view hierarchy. We'll add our environment to the ",Object(a.b)("inlineCode",{parentName:"p"},"ContentView")," that is created in our ",Object(a.b)("inlineCode",{parentName:"p"},"App"),"."),Object(a.b)("pre",null,Object(a.b)("code",{parentName:"pre",className:"language-swift"},"import SwiftUI\nimport RelaySwiftUI\n\nlet environment = Environment(\n    network: Network(),\n    store: Store()\n)\n\n@main\nstruct ToDoApp: App {\n    var body: some Scene {\n        WindowGroup {\n            ContentView()\n                .relayEnvironment(environment)\n        }\n    }\n}\n")),Object(a.b)("p",null,"Now child views of ",Object(a.b)("inlineCode",{parentName:"p"},"ContentView")," will be able to use the environment to perform queries and load data."))}p.isMDXComponent=!0}}]);