(window.webpackJsonp=window.webpackJsonp||[]).push([[32],{154:function(e,t,n){"use strict";n.d(t,"a",(function(){return d})),n.d(t,"b",(function(){return h}));var a=n(0),r=n.n(a);function i(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function o(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var a=Object.getOwnPropertySymbols(e);t&&(a=a.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,a)}return n}function s(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?o(Object(n),!0).forEach((function(t){i(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):o(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function l(e,t){if(null==e)return{};var n,a,r=function(e,t){if(null==e)return{};var n,a,r={},i=Object.keys(e);for(a=0;a<i.length;a++)n=i[a],t.indexOf(n)>=0||(r[n]=e[n]);return r}(e,t);if(Object.getOwnPropertySymbols){var i=Object.getOwnPropertySymbols(e);for(a=0;a<i.length;a++)n=i[a],t.indexOf(n)>=0||Object.prototype.propertyIsEnumerable.call(e,n)&&(r[n]=e[n])}return r}var c=r.a.createContext({}),p=function(e){var t=r.a.useContext(c),n=t;return e&&(n="function"==typeof e?e(t):s(s({},t),e)),n},d=function(e){var t=p(e.components);return r.a.createElement(c.Provider,{value:t},e.children)},m={inlineCode:"code",wrapper:function(e){var t=e.children;return r.a.createElement(r.a.Fragment,{},t)}},u=r.a.forwardRef((function(e,t){var n=e.components,a=e.mdxType,i=e.originalType,o=e.parentName,c=l(e,["components","mdxType","originalType","parentName"]),d=p(n),u=a,h=d["".concat(o,".").concat(u)]||d[u]||m[u]||i;return n?r.a.createElement(h,s(s({ref:t},c),{},{components:n})):r.a.createElement(h,s({ref:t},c))}));function h(e,t){var n=arguments,a=t&&t.mdxType;if("string"==typeof e||a){var i=n.length,o=new Array(i);o[0]=u;var s={};for(var l in t)hasOwnProperty.call(t,l)&&(s[l]=t[l]);s.originalType=e,s.mdxType="string"==typeof e?e:a,o[1]=s;for(var c=2;c<i;c++)o[c]=n[c];return r.a.createElement.apply(null,o)}return r.a.createElement.apply(null,n)}u.displayName="MDXCreateElement"},97:function(e,t,n){"use strict";n.r(t),n.d(t,"frontMatter",(function(){return o})),n.d(t,"metadata",(function(){return s})),n.d(t,"toc",(function(){return l})),n.d(t,"default",(function(){return p}));var a=n(3),r=n(7),i=(n(0),n(154)),o={title:"@Fragment"},s={unversionedId:"api/fragment",id:"api/fragment",isDocsHomePage:!1,title:"@Fragment",description:"The @Fragment property wrapper allows a SwiftUI view to specify exactly the data it needs to be able to render and guarantee that data will be fetched by a @Query higher in the view tree.",source:"@site/docs/api/fragment.md",slug:"/api/fragment",permalink:"/Relay.swift/docs/next/api/fragment",editUrl:"https://github.com/relay-tools/Relay.swift/edit/main/website/docs/api/fragment.md",version:"current",sidebar:"docs",previous:{title:"@Query",permalink:"/Relay.swift/docs/next/api/query"},next:{title:"@RefetchableFragment",permalink:"/Relay.swift/docs/next/api/refetchable-fragment"}},l=[{value:"Example",id:"example",children:[]},{value:"Passing data into fragment views",id:"passing-data-into-fragment-views",children:[{value:"Masking",id:"masking",children:[]}]}],c={toc:l};function p(e){var t=e.components,n=Object(r.a)(e,["components"]);return Object(i.b)("wrapper",Object(a.a)({},c,n,{components:t,mdxType:"MDXLayout"}),Object(i.b)("p",null,"The ",Object(i.b)("inlineCode",{parentName:"p"},"@Fragment")," property wrapper allows a SwiftUI view to specify exactly the data it needs to be able to render and guarantee that data will be fetched by a ",Object(i.b)("a",{parentName:"p",href:"/Relay.swift/docs/next/api/query"},"@Query")," higher in the view tree."),Object(i.b)("p",null,"Using fragments isolates views from needing to know details about what data other views depend on. They allow views to be reused in different parts of the app with zero risk of forgetting to fetch necessary data. When using fragments, the Swift and Relay compilers work together to ensure that queries include all data that is needed by all child views and that the data is being passed between views correctly."),Object(i.b)("h2",{id:"example"},"Example"),Object(i.b)("pre",null,Object(i.b)("code",{parentName:"pre",className:"language-swift"},'import SwiftUI\nimport RelaySwiftUI\n\nprivate let itemFragment = graphql("""\nfragment ToDoItem_item on Item {\n  text\n  complete\n}\n""")\n\nstruct ToDoItem: View {\n  @Fragment<ToDoItem_item> var item\n\n    var body: some View {\n        Group {\n            if let item = item {\n                HStack {\n                    Image(systemName: item.complete ? "checkmark.square" : "square")\n                    Text("\\(item.text)")\n                }\n            }\n        }\n    }\n}\n')),Object(i.b)("h2",{id:"passing-data-into-fragment-views"},"Passing data into fragment views"),Object(i.b)("p",null,"Fragments don't fetch any data themselves. Instead, they expect it to be fetched by a view higher up in the tree using ",Object(i.b)("a",{parentName:"p",href:"/Relay.swift/docs/next/api/query"},"@Query"),". To ensure the data the fragment needs is fetched by the query, you must spread the fragment into the GraphQL query. Once you've done so, you should be able to pass the data along to a child view that's using ",Object(i.b)("inlineCode",{parentName:"p"},"@Fragment"),":"),Object(i.b)("pre",null,Object(i.b)("code",{parentName:"pre",className:"language-swift"},'private let query = graphql("""\nquery ToDoListQuery {\n    list(id: "abc") {\n        items {\n            ...ToDoItem_item\n        }\n    }\n}\n""")\n\nstruct ToDoList: View {\n    @Query<ToDoListQuery> var query\n\n    var body: some View {\n        switch query.get() {\n        case .loading:\n            Text("Loading...")\n        case .failure(let error):\n            Text("Error: \\(error.localizedDescription)")\n        case .success(let data):\n            List(data?.list?.items ?? [], id: \\.id) { toDoItem in\n                ToDoItem(item: toDoItem.asFragment())\n            }\n        }\n    }\n}\n')),Object(i.b)("p",null,"To pass the fragment along to the child view, call ",Object(i.b)("inlineCode",{parentName:"p"},"asFragment()")," on the value where the fragment was spread. This creates a value of the ",Object(i.b)("inlineCode",{parentName:"p"},"Fragment")," type that matches the property declared on the child view using ",Object(i.b)("inlineCode",{parentName:"p"},"@Fragment"),"."),Object(i.b)("p",null,"Fragments can also be spread into other fragments (not just queries), allowing for arbitrarily deep view trees where each view requests exactly the data it needs."),Object(i.b)("h3",{id:"masking"},"Masking"),Object(i.b)("p",null,"While spreading a fragment into a GraphQL query includes the necessary fields in the query that is sent to the server, it ",Object(i.b)("strong",{parentName:"p"},"does not")," make those fields available to the view. In the examples above, for instance, the ",Object(i.b)("inlineCode",{parentName:"p"},"ToDoList")," view cannot read the ",Object(i.b)("inlineCode",{parentName:"p"},"text")," or ",Object(i.b)("inlineCode",{parentName:"p"},"checked")," properties of any to-do items, even though they were fetched as part of the query. Instead, the type generated for to-do items for the ",Object(i.b)("inlineCode",{parentName:"p"},"ToDoListQuery")," conforms to the ",Object(i.b)("inlineCode",{parentName:"p"},"ToDoItem_item_Key"),' protocol and includes a "pointer" to the data for that to-do item in the Relay store. The ',Object(i.b)("inlineCode",{parentName:"p"},"@Fragment")," property wrapper will use that pointer to look up the data that the ",Object(i.b)("inlineCode",{parentName:"p"},"ToDoItem")," view needs."),Object(i.b)("p",null,"It may seem unnecessary to go to all this trouble to make views hide data from each other, but it has significant benefits as you're working on your app. It means that each view in your application always specifies exactly what data it depends on in the same file as the code that uses that data. If you need to change which fields your view needs, you can just update your GraphQL fragment and you're good to go. The query that fetches the data doesn't need any changes because it doesn't even know what your component needs in the first place."),Object(i.b)("h4",{id:"parameters"},"Parameters"),Object(i.b)("ul",null,Object(i.b)("li",{parentName:"ul"},Object(i.b)("inlineCode",{parentName:"li"},"F"),": A type parameter (surrounded in ",Object(i.b)("inlineCode",{parentName:"li"},"<>"),") for the type of the fragment to use. The type will be generated by the Relay compiler with a name matching the fragment name in the GraphQL snippet.")),Object(i.b)("h4",{id:"property-value"},"Property value"),Object(i.b)("p",null,"The ",Object(i.b)("inlineCode",{parentName:"p"},"@Fragment")," property will be a read-only optional value with the fields the fragment requests."))}p.isMDXComponent=!0}}]);