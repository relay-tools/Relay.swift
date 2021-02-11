(window.webpackJsonp=window.webpackJsonp||[]).push([[16],{154:function(e,t,n){"use strict";n.d(t,"a",(function(){return u})),n.d(t,"b",(function(){return b}));var a=n(0),i=n.n(a);function o(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function r(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var a=Object.getOwnPropertySymbols(e);t&&(a=a.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,a)}return n}function c(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?r(Object(n),!0).forEach((function(t){o(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):r(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function p(e,t){if(null==e)return{};var n,a,i=function(e,t){if(null==e)return{};var n,a,i={},o=Object.keys(e);for(a=0;a<o.length;a++)n=o[a],t.indexOf(n)>=0||(i[n]=e[n]);return i}(e,t);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);for(a=0;a<o.length;a++)n=o[a],t.indexOf(n)>=0||Object.prototype.propertyIsEnumerable.call(e,n)&&(i[n]=e[n])}return i}var l=i.a.createContext({}),s=function(e){var t=i.a.useContext(l),n=t;return e&&(n="function"==typeof e?e(t):c(c({},t),e)),n},u=function(e){var t=s(e.components);return i.a.createElement(l.Provider,{value:t},e.children)},d={inlineCode:"code",wrapper:function(e){var t=e.children;return i.a.createElement(i.a.Fragment,{},t)}},m=i.a.forwardRef((function(e,t){var n=e.components,a=e.mdxType,o=e.originalType,r=e.parentName,l=p(e,["components","mdxType","originalType","parentName"]),u=s(n),m=a,b=u["".concat(r,".").concat(m)]||u[m]||d[m]||o;return n?i.a.createElement(b,c(c({ref:t},l),{},{components:n})):i.a.createElement(b,c({ref:t},l))}));function b(e,t){var n=arguments,a=t&&t.mdxType;if("string"==typeof e||a){var o=n.length,r=new Array(o);r[0]=m;var c={};for(var p in t)hasOwnProperty.call(t,p)&&(c[p]=t[p]);c.originalType=e,c.mdxType="string"==typeof e?e:a,r[1]=c;for(var l=2;l<o;l++)r[l]=n[l];return i.a.createElement.apply(null,r)}return i.a.createElement.apply(null,n)}m.displayName="MDXCreateElement"},81:function(e,t,n){"use strict";n.r(t),n.d(t,"frontMatter",(function(){return r})),n.d(t,"metadata",(function(){return c})),n.d(t,"toc",(function(){return p})),n.d(t,"default",(function(){return s}));var a=n(3),i=n(7),o=(n(0),n(154)),r={title:"Environment"},c={unversionedId:"api/environment",id:"api/environment",isDocsHomePage:!1,title:"Environment",description:"`swift",source:"@site/docs/api/environment.md",slug:"/api/environment",permalink:"/Relay.swift/docs/next/api/environment",editUrl:"https://github.com/relay-tools/Relay.swift/edit/main/website/docs/api/environment.md",version:"current",sidebar:"docs",previous:{title:"GraphQL tagged strings",permalink:"/Relay.swift/docs/next/api/graphql"},next:{title:"Network layer",permalink:"/Relay.swift/docs/next/api/network"}},p=[{value:"Creating an environment",id:"creating-an-environment",children:[{value:"<code>init</code>",id:"init",children:[]}]},{value:"Fetching data outside a view",id:"fetching-data-outside-a-view",children:[{value:"<code>fetchQuery</code>",id:"fetchquery",children:[]}]},{value:"Running mutations outside a view",id:"running-mutations-outside-a-view",children:[{value:"<code>commitMutation</code>",id:"commitmutation",children:[]}]},{value:"Updating the store manually",id:"updating-the-store-manually",children:[{value:"<code>commitUpdate(_:)</code>",id:"commitupdate_",children:[]}]}],l={toc:p};function s(e){var t=e.components,n=Object(i.a)(e,["components"]);return Object(o.b)("wrapper",Object(a.a)({},l,n,{components:t,mdxType:"MDXLayout"}),Object(o.b)("pre",null,Object(o.b)("code",{parentName:"pre",className:"language-swift"},"class Environment\n")),Object(o.b)("p",null,"The ",Object(o.b)("inlineCode",{parentName:"p"},"Environment")," combines all the things that Relay.swift needs to be able to work. You use an environment to fetch queries and load stored records. Any views in your app that need to use Relay will need access to the environment to do so."),Object(o.b)("h2",{id:"creating-an-environment"},"Creating an environment"),Object(o.b)("h3",{id:"init"},Object(o.b)("inlineCode",{parentName:"h3"},"init")),Object(o.b)("pre",null,Object(o.b)("code",{parentName:"pre",className:"language-swift"},"init(\n    network: Network,\n    store: Store,\n    handlerProvider: HandlerProvider = DefaultHandlerProvider()\n)\n")),Object(o.b)("p",null,"An environment needs two things at a minimum:"),Object(o.b)("ul",null,Object(o.b)("li",{parentName:"ul"},"A ",Object(o.b)("a",{parentName:"li",href:"/Relay.swift/docs/next/api/network"},"Network Layer")," to tell it how to communicate with your GraphQL API"),Object(o.b)("li",{parentName:"ul"},"A ",Object(o.b)("a",{parentName:"li",href:"/Relay.swift/docs/next/api/store"},"Store")," for keeping track of data locally")),Object(o.b)("p",null,"Once you've created it, you probably want to keep the same Environment instance for the lifetime of your app. In SwiftUI, you can use ",Object(o.b)("a",{parentName:"p",href:"/Relay.swift/docs/next/api/relay-environment-modifier"},"relayEnvironment()")," to provide this to your views."),Object(o.b)("h2",{id:"fetching-data-outside-a-view"},"Fetching data outside a view"),Object(o.b)("h3",{id:"fetchquery"},Object(o.b)("inlineCode",{parentName:"h3"},"fetchQuery")),Object(o.b)("pre",null,Object(o.b)("code",{parentName:"pre",className:"language-swift"},"func fetchQuery<Op: Operation>(\n    _ operation: Op,\n    cacheConfig: CacheConfig = .init()\n) -> AnyPublisher<Op.Data?, Error>\n")),Object(o.b)("p",null,"The ",Object(o.b)("inlineCode",{parentName:"p"},"fetchQuery")," method allows you to perform a query without displaying the data in a view. Sometimes this can be useful to update the local store with new data in response to an event, or if you  need access to a query's data in a background task."),Object(o.b)("p",null,"If you want to show query data in a SwiftUI view, use the ",Object(o.b)("a",{parentName:"p",href:"/Relay.swift/docs/next/api/query"},"@Query")," property wrapper."),Object(o.b)("h2",{id:"running-mutations-outside-a-view"},"Running mutations outside a view"),Object(o.b)("h3",{id:"commitmutation"},Object(o.b)("inlineCode",{parentName:"h3"},"commitMutation")),Object(o.b)("pre",null,Object(o.b)("code",{parentName:"pre",className:"language-swift"},"func commitMutation<Op: Operation>(\n  _ operation: Op,\n  optimisticResponse: [String: Any]? = nil,\n  optimisticUpdater: SelectorStoreUpdater? = nil,\n  updater: SelectorStoreUpdater? = nil\n) -> AnyPublisher<Op.Data?, Error>\n")),Object(o.b)("p",null,"The ",Object(o.b)("inlineCode",{parentName:"p"},"commitMutation")," method allows you to execute a mutation to update data on the server. You can use this if you need to execute a mutation outside your views."),Object(o.b)("p",null,"Note that you need to subscribe to the publisher that is returned (using ",Object(o.b)("inlineCode",{parentName:"p"},"sink")," or ",Object(o.b)("inlineCode",{parentName:"p"},"assign"),") in order for your mutation to actually execute, and if that subscription is canceled early for some reason, you may not see the updates you expect."),Object(o.b)("p",null,"If you want to run a mutation in response to input from a SwiftUI view, use the ",Object(o.b)("a",{parentName:"p",href:"/Relay.swift/docs/next/api/mutation"},"@Mutation")," property wrapper, which manages this for you and makes it easy to show progress state in your UI while the mutation is running."),Object(o.b)("p",null,"For more information about how to use the ",Object(o.b)("inlineCode",{parentName:"p"},"updater")," and ",Object(o.b)("inlineCode",{parentName:"p"},"optimisticUpdater")," parameters, see ",Object(o.b)("a",{parentName:"p",href:"/Relay.swift/docs/next/knowledge-base/updater-functions"},"Updater functions"),"."),Object(o.b)("h2",{id:"updating-the-store-manually"},"Updating the store manually"),Object(o.b)("h3",{id:"commitupdate_"},Object(o.b)("inlineCode",{parentName:"h3"},"commitUpdate(_:)")),Object(o.b)("pre",null,Object(o.b)("code",{parentName:"pre",className:"language-swift"},"func commitUpdate(\n    _ updater: @escaping StoreUpdater\n)\n")),Object(o.b)("p",null,"The ",Object(o.b)("inlineCode",{parentName:"p"},"commitUpdate")," method allows you to perform updates to Relay's store outside the context of a mutation."),Object(o.b)("p",null,"The main reason to do this is to add client-only data to the store. The ",Object(o.b)("inlineCode",{parentName:"p"},"StoreUpdater")," function you pass in is similar to the ",Object(o.b)("inlineCode",{parentName:"p"},"SelectorStoreUpdater")," used for mutations, but without the methods and arguments for information provided by the mutation's response."),Object(o.b)("div",{className:"admonition admonition-note alert alert--secondary"},Object(o.b)("div",{parentName:"div",className:"admonition-heading"},Object(o.b)("h5",{parentName:"div"},Object(o.b)("span",{parentName:"h5",className:"admonition-icon"},Object(o.b)("svg",{parentName:"span",xmlns:"http://www.w3.org/2000/svg",width:"14",height:"16",viewBox:"0 0 14 16"},Object(o.b)("path",{parentName:"svg",fillRule:"evenodd",d:"M6.3 5.69a.942.942 0 0 1-.28-.7c0-.28.09-.52.28-.7.19-.18.42-.28.7-.28.28 0 .52.09.7.28.18.19.28.42.28.7 0 .28-.09.52-.28.7a1 1 0 0 1-.7.3c-.28 0-.52-.11-.7-.3zM8 7.99c-.02-.25-.11-.48-.31-.69-.2-.19-.42-.3-.69-.31H6c-.27.02-.48.13-.69.31-.2.2-.3.44-.31.69h1v3c.02.27.11.5.31.69.2.2.42.31.69.31h1c.27 0 .48-.11.69-.31.2-.19.3-.42.31-.69H8V7.98v.01zM7 2.3c-3.14 0-5.7 2.54-5.7 5.68 0 3.14 2.56 5.7 5.7 5.7s5.7-2.55 5.7-5.7c0-3.15-2.56-5.69-5.7-5.69v.01zM7 .98c3.86 0 7 3.14 7 7s-3.14 7-7 7-7-3.12-7-7 3.14-7 7-7z"}))),"note")),Object(o.b)("div",{parentName:"div",className:"admonition-content"},Object(o.b)("p",{parentName:"div"},"We may document ",Object(o.b)("inlineCode",{parentName:"p"},"Environment"),"'s other public methods at some point, but they're largely there to implement higher-level APIs like ",Object(o.b)("inlineCode",{parentName:"p"},"RelaySwiftUI"),"."))))}s.isMDXComponent=!0}}]);