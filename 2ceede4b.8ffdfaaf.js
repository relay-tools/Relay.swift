(window.webpackJsonp=window.webpackJsonp||[]).push([[14],{122:function(e,t,n){"use strict";n.d(t,"a",(function(){return s})),n.d(t,"b",(function(){return f}));var r=n(0),a=n.n(r);function i(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function o(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);t&&(r=r.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,r)}return n}function l(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?o(Object(n),!0).forEach((function(t){i(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):o(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function c(e,t){if(null==e)return{};var n,r,a=function(e,t){if(null==e)return{};var n,r,a={},i=Object.keys(e);for(r=0;r<i.length;r++)n=i[r],t.indexOf(n)>=0||(a[n]=e[n]);return a}(e,t);if(Object.getOwnPropertySymbols){var i=Object.getOwnPropertySymbols(e);for(r=0;r<i.length;r++)n=i[r],t.indexOf(n)>=0||Object.prototype.propertyIsEnumerable.call(e,n)&&(a[n]=e[n])}return a}var p=a.a.createContext({}),u=function(e){var t=a.a.useContext(p),n=t;return e&&(n="function"==typeof e?e(t):l(l({},t),e)),n},s=function(e){var t=u(e.components);return a.a.createElement(p.Provider,{value:t},e.children)},b={inlineCode:"code",wrapper:function(e){var t=e.children;return a.a.createElement(a.a.Fragment,{},t)}},d=a.a.forwardRef((function(e,t){var n=e.components,r=e.mdxType,i=e.originalType,o=e.parentName,p=c(e,["components","mdxType","originalType","parentName"]),s=u(n),d=r,f=s["".concat(o,".").concat(d)]||s[d]||b[d]||i;return n?a.a.createElement(f,l(l({ref:t},p),{},{components:n})):a.a.createElement(f,l({ref:t},p))}));function f(e,t){var n=arguments,r=t&&t.mdxType;if("string"==typeof e||r){var i=n.length,o=new Array(i);o[0]=d;var l={};for(var c in t)hasOwnProperty.call(t,c)&&(l[c]=t[c]);l.originalType=e,l.mdxType="string"==typeof e?e:r,o[1]=l;for(var p=2;p<i;p++)o[p]=n[p];return a.a.createElement.apply(null,o)}return a.a.createElement.apply(null,n)}d.displayName="MDXCreateElement"},79:function(e,t,n){"use strict";n.r(t),n.d(t,"frontMatter",(function(){return o})),n.d(t,"metadata",(function(){return l})),n.d(t,"toc",(function(){return c})),n.d(t,"default",(function(){return u}));var r=n(3),a=n(7),i=(n(0),n(122)),o={title:"GraphQL tagged strings"},l={unversionedId:"api/graphql",id:"api/graphql",isDocsHomePage:!1,title:"GraphQL tagged strings",description:"`swift",source:"@site/docs/api/graphql.md",slug:"/api/graphql",permalink:"/Relay.swift/docs/api/graphql",editUrl:"https://github.com/relay-tools/Relay.swift/edit/main/website/docs/api/graphql.md",version:"current",sidebar:"docs",previous:{title:"Introduction",permalink:"/Relay.swift/docs/api/intro-relay"},next:{title:"Environment",permalink:"/Relay.swift/docs/api/environment"}},c=[],p={toc:c};function u(e){var t=e.components,n=Object(a.a)(e,["components"]);return Object(i.b)("wrapper",Object(r.a)({},p,n,{components:t,mdxType:"MDXLayout"}),Object(i.b)("pre",null,Object(i.b)("code",{parentName:"pre",className:"language-swift"},"func graphql(_ query: String) -> TaggedGraphQLQuery\n")),Object(i.b)("p",null,"The ",Object(i.b)("inlineCode",{parentName:"p"},"graphql")," function is used to tag GraphQL strings in your application."),Object(i.b)("p",null,"When you run the Relay compiler, it will scan your source code for multiline string literals wrapped in the ",Object(i.b)("inlineCode",{parentName:"p"},"graphql")," function, and it will use those queries and fragments to perform ",Object(i.b)("a",{parentName:"p",href:"/Relay.swift/docs/knowledge-base/updater-functions"},"How code generation works"),"."),Object(i.b)("p",null,"Your GraphQL strings should be assigned to private constants (",Object(i.b)("inlineCode",{parentName:"p"},"private let foo = ..."),") in the source file that uses the query or fragment. There are some conventions for naming the constant:"),Object(i.b)("ul",null,Object(i.b)("li",{parentName:"ul"},"Queries: ",Object(i.b)("inlineCode",{parentName:"li"},"query"),"."),Object(i.b)("li",{parentName:"ul"},"Mutations: ",Object(i.b)("inlineCode",{parentName:"li"},"mutation"),"."),Object(i.b)("li",{parentName:"ul"},"Fragments: ",Object(i.b)("inlineCode",{parentName:"li"},"<paramName>Fragment"),". For instance, if your view takes a ",Object(i.b)("inlineCode",{parentName:"li"},"todo")," parameter that is a fragment, call the GraphQL string constant ",Object(i.b)("inlineCode",{parentName:"li"},"todoFragment"),".")),Object(i.b)("p",null,"The result of the ",Object(i.b)("inlineCode",{parentName:"p"},"graphql")," function is not directly used. When using Relay in JavaScript, you write your GraphQL code directly in places where you would reference your query or fragment type, and a Babel plugin replaces it with an import of the code the Relay compiler generates. Swift doesn't have anything like Babel for doing arbitrary transforms at build time, so we have to be a little more indirect."))}u.isMDXComponent=!0}}]);