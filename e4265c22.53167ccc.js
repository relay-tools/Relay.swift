(window.webpackJsonp=window.webpackJsonp||[]).push([[75],{140:function(e,t,n){"use strict";n.r(t),n.d(t,"frontMatter",(function(){return o})),n.d(t,"metadata",(function(){return s})),n.d(t,"toc",(function(){return c})),n.d(t,"default",(function(){return u}));var r=n(3),a=n(7),i=(n(0),n(154)),o={title:"Fetching data with queries",hide_table_of_contents:!0},s={unversionedId:"getting-started/fetching-data",id:"getting-started/fetching-data",isDocsHomePage:!1,title:"Fetching data with queries",description:"Now that we've set up an environment, we can start fetching data and rendering it in our views. We'll start with something simple",source:"@site/docs/getting-started/fetching-data.md",slug:"/getting-started/fetching-data",permalink:"/Relay.swift/docs/next/getting-started/fetching-data",editUrl:"https://github.com/relay-tools/Relay.swift/edit/main/website/docs/getting-started/fetching-data.md",version:"current",sidebar:"docs",previous:{title:"The Relay environment",permalink:"/Relay.swift/docs/next/getting-started/relay-environment"},next:{title:"Composing views with fragments",permalink:"/Relay.swift/docs/next/getting-started/fragments"}},c=[{value:"Dynamic queries using variables",id:"dynamic-queries-using-variables",children:[]}],l={toc:c};function u(e){var t=e.components,n=Object(a.a)(e,["components"]);return Object(i.b)("wrapper",Object(r.a)({},l,n,{components:t,mdxType:"MDXLayout"}),Object(i.b)("p",null,"Now that we've set up an environment, we can start fetching data and rendering it in our views. We'll start with something simple: just rendering the ID of the current user. The first thing we want to do is write our GraphQL query into our view's source file, ",Object(i.b)("inlineCode",{parentName:"p"},"UserView.swift"),":"),Object(i.b)("pre",null,Object(i.b)("code",{parentName:"pre",className:"language-swift"},'import SwiftUI\nimport RelaySwiftUI\n\nprivate let query = graphql("""\nquery UserViewQuery {\n  viewer {\n    id\n  }\n}\n""")\n')),Object(i.b)("p",null,"The ",Object(i.b)("inlineCode",{parentName:"p"},"graphql")," function doesn't do anything in our Swift code, but it's a marker that allows the Relay compiler to find our queries and generate code and types for them. Let's generate those now:"),Object(i.b)("pre",null,Object(i.b)("code",{parentName:"pre"},"$ npx relay-compiler\n")),Object(i.b)("p",null,"The compiler should create a file at ",Object(i.b)("inlineCode",{parentName:"p"},"__generated__/UserViewQuery.graphql.swift"),". We must add the new file to our Xcode project so it gets built into our app. This file contains types that help Relay execute the query and that allow our view to read the data it returns."),Object(i.b)("p",null,"Now we can use our query in a SwiftUI view:"),Object(i.b)("pre",null,Object(i.b)("code",{parentName:"pre",className:"language-swift"},'import SwiftUI\nimport RelaySwiftUI\n\nprivate let query = graphql("""\nquery UserViewQuery {\n  viewer {\n    id\n  }\n}\n""")\n\nstruct UserView: View {\n    @Query<UserViewQuery> var query\n\n    var body: some View {\n        switch query.get() {\n        case .loading:\n            Text("Loading...")\n        case .failure(let error):\n            Text("Error: \\(error.localizedDescription)")\n        case .success(let data):\n            Text("User ID: \\(data?.viewer?.id ?? "none")")\n        }\n    }\n}\n')),Object(i.b)("p",null,"We're using the ",Object(i.b)("a",{parentName:"p",href:"/Relay.swift/docs/next/api/query"},"@Query")," property wrapper provided by Relay.swift to load this data in our view. When we try to render the first time, the query will start loading its data and will return ",Object(i.b)("inlineCode",{parentName:"p"},".loading")," from ",Object(i.b)("inlineCode",{parentName:"p"},"query.get()"),". Once the request has finished, our view will re-render its body with either ",Object(i.b)("inlineCode",{parentName:"p"},".failure")," or ",Object(i.b)("inlineCode",{parentName:"p"},".success")," as the result."),Object(i.b)("p",null,"The ",Object(i.b)("inlineCode",{parentName:"p"},"data")," in the ",Object(i.b)("inlineCode",{parentName:"p"},".success")," result has the type ",Object(i.b)("inlineCode",{parentName:"p"},"UserViewQuery.Data?"),". This structure is generated by the Relay compiler using our GraphQL schema to match the exact shape of the data requested by our query. We get automatic type-safe access to our data without having to write any serialization code."),Object(i.b)("p",null,"This is great: we're able to declare what data our view needs as well as what the view should look like in each possible state for fetching that data."),Object(i.b)("h2",{id:"dynamic-queries-using-variables"},"Dynamic queries using variables"),Object(i.b)("p",null,"Suppose we wanted to show information about other users, not just the current one. We can write a query that asks for the node with a given ID, and have our view take that ID in its initializer:"),Object(i.b)("pre",null,Object(i.b)("code",{parentName:"pre",className:"language-swift"},'import SwiftUI\nimport RelaySwiftUI\n\nprivate let query = graphql("""\nquery UserViewQuery($userID: ID!) {\n  node(id: $userID) {\n    id\n  }\n}\n""")\n\nstruct UserView: View {\n    @Query<UserViewQuery> var query\n    \n    let id: String\n\n    var body: some View {\n        switch query.get(userID: id) {\n        case .loading:\n            Text("Loading...")\n        case .failure(let error):\n            Text("Error: \\(error.localizedDescription)")\n        case .success(let data):\n            Text("User ID: \\(data?.viewer?.id ?? "none")")\n        }\n    }\n}\n')),Object(i.b)("p",null,"That's a pretty small change from what we had before. Now our GraphQL query takes in a variable called ",Object(i.b)("inlineCode",{parentName:"p"},"userID"),". Because we changed the query, we need to run ",Object(i.b)("inlineCode",{parentName:"p"},"npx relay-compiler")," to regenerate the corresponding Swift types."),Object(i.b)("p",null,"The Relay compiler generated a new variant of ",Object(i.b)("inlineCode",{parentName:"p"},"query.get")," for us that matches the variables we declared in our GraphQL query. When we render our view, we pass in the variables we want the query to use. In this case, we get the value for the ",Object(i.b)("inlineCode",{parentName:"p"},"userID")," variable as input to our view when it's initialized, but you can also use ",Object(i.b)("inlineCode",{parentName:"p"},"@State")," properties or other ways that SwiftUI has to keep track of data."),Object(i.b)("p",null,"You can learn more about using queries in the ",Object(i.b)("a",{parentName:"p",href:"/Relay.swift/docs/next/api/query"},"@Query")," API docs. For now, let's see how to compose views together while loading data with Relay."))}u.isMDXComponent=!0},154:function(e,t,n){"use strict";n.d(t,"a",(function(){return p})),n.d(t,"b",(function(){return b}));var r=n(0),a=n.n(r);function i(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function o(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);t&&(r=r.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,r)}return n}function s(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?o(Object(n),!0).forEach((function(t){i(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):o(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function c(e,t){if(null==e)return{};var n,r,a=function(e,t){if(null==e)return{};var n,r,a={},i=Object.keys(e);for(r=0;r<i.length;r++)n=i[r],t.indexOf(n)>=0||(a[n]=e[n]);return a}(e,t);if(Object.getOwnPropertySymbols){var i=Object.getOwnPropertySymbols(e);for(r=0;r<i.length;r++)n=i[r],t.indexOf(n)>=0||Object.prototype.propertyIsEnumerable.call(e,n)&&(a[n]=e[n])}return a}var l=a.a.createContext({}),u=function(e){var t=a.a.useContext(l),n=t;return e&&(n="function"==typeof e?e(t):s(s({},t),e)),n},p=function(e){var t=u(e.components);return a.a.createElement(l.Provider,{value:t},e.children)},d={inlineCode:"code",wrapper:function(e){var t=e.children;return a.a.createElement(a.a.Fragment,{},t)}},h=a.a.forwardRef((function(e,t){var n=e.components,r=e.mdxType,i=e.originalType,o=e.parentName,l=c(e,["components","mdxType","originalType","parentName"]),p=u(n),h=r,b=p["".concat(o,".").concat(h)]||p[h]||d[h]||i;return n?a.a.createElement(b,s(s({ref:t},l),{},{components:n})):a.a.createElement(b,s({ref:t},l))}));function b(e,t){var n=arguments,r=t&&t.mdxType;if("string"==typeof e||r){var i=n.length,o=new Array(i);o[0]=h;var s={};for(var c in t)hasOwnProperty.call(t,c)&&(s[c]=t[c]);s.originalType=e,s.mdxType="string"==typeof e?e:r,o[1]=s;for(var l=2;l<i;l++)o[l]=n[l];return a.a.createElement.apply(null,o)}return a.a.createElement.apply(null,n)}h.displayName="MDXCreateElement"}}]);