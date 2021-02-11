(window.webpackJsonp=window.webpackJsonp||[]).push([[51],{116:function(e,t,n){"use strict";n.r(t),n.d(t,"frontMatter",(function(){return r})),n.d(t,"metadata",(function(){return l})),n.d(t,"toc",(function(){return c})),n.d(t,"default",(function(){return s}));var i=n(3),a=n(7),o=(n(0),n(154)),r={title:"Contributing to Relay.swift",sidebar_label:"Contributing"},l={unversionedId:"development/contributing",id:"development/contributing",isDocsHomePage:!1,title:"Contributing to Relay.swift",description:"So far, Relay.swift is mostly developed by Matt Moriarity. But if you're interested, you are welcome to contribute too! This page is intended to help you get up to speed on how to develop on Relay.swift.",source:"@site/docs/development/contributing.md",slug:"/development/contributing",permalink:"/Relay.swift/docs/next/development/contributing",editUrl:"https://github.com/relay-tools/Relay.swift/edit/main/website/docs/development/contributing.md",version:"current",sidebar_label:"Contributing",sidebar:"docs",previous:{title:"previewPayload()",permalink:"/Relay.swift/docs/next/api/preview-payload"}},c=[{value:"Building and testing",id:"building-and-testing",children:[{value:"Swift code",id:"swift-code",children:[]},{value:"TypeScript code",id:"typescript-code",children:[]}]},{value:"Releasing a new version",id:"releasing-a-new-version",children:[]}],p={toc:c};function s(e){var t=e.components,n=Object(a.a)(e,["components"]);return Object(o.b)("wrapper",Object(i.a)({},p,n,{components:t,mdxType:"MDXLayout"}),Object(o.b)("p",null,"So far, Relay.swift is mostly developed by ",Object(o.b)("a",{parentName:"p",href:"https://www.mattmoriarity.com"},"Matt Moriarity"),". But if you're interested, you are welcome to contribute too! This page is intended to help you get up to speed on how to develop on Relay.swift."),Object(o.b)("h2",{id:"building-and-testing"},"Building and testing"),Object(o.b)("h3",{id:"swift-code"},"Swift code"),Object(o.b)("p",null,"You can generally using any SwiftPM tooling to develop on the Relay.swift package. This includes the ",Object(o.b)("inlineCode",{parentName:"p"},"swift")," CLI as well as Xcode's built-in support for opening SwiftPM packages as projects."),Object(o.b)("p",null,"There are currently four source targets in the package:"),Object(o.b)("ul",null,Object(o.b)("li",{parentName:"ul"},Object(o.b)("inlineCode",{parentName:"li"},"Relay"),": the core code to implement Relay, independent of UI framework"),Object(o.b)("li",{parentName:"ul"},Object(o.b)("inlineCode",{parentName:"li"},"RelaySwiftUI"),": SwiftUI-specific support for Relay"),Object(o.b)("li",{parentName:"ul"},Object(o.b)("inlineCode",{parentName:"li"},"RelayTestHelpers"),": shared code that is used by tests for both ",Object(o.b)("inlineCode",{parentName:"li"},"Relay")," and ",Object(o.b)("inlineCode",{parentName:"li"},"RelaySwiftUI")),Object(o.b)("li",{parentName:"ul"},Object(o.b)("inlineCode",{parentName:"li"},"find-graphql-tags"),": a CLI tool that is packaged with the relay-compiler JS plugin to discover ",Object(o.b)("a",{parentName:"li",href:"/Relay.swift/docs/next/api/graphql"},"GraphQL tagged strings")," in sources")),Object(o.b)("p",null,"The first two source targets also have corresponding test targets. You can run these tests either in Xcode or with ",Object(o.b)("inlineCode",{parentName:"p"},"swift test"),"."),Object(o.b)("p",null,"There are also three example apps which demonstrate how to use RelaySwiftUI in practice. These apps are contained in the ",Object(o.b)("inlineCode",{parentName:"p"},"RelayExamples.xcodeproj")," Xcode project. This project is configured to use the Relay.swift package in the working copy."),Object(o.b)("h3",{id:"typescript-code"},"TypeScript code"),Object(o.b)("p",null,"Relay.swift also contains a plugin for the relay-compiler to allow it to generate Swift code. This is an npm package in the ",Object(o.b)("inlineCode",{parentName:"p"},"relay-compiler-language-swift")," directory."),Object(o.b)("p",null,"The package includes Jest tests that can be run using ",Object(o.b)("inlineCode",{parentName:"p"},"npm test")," in that directory."),Object(o.b)("p",null,"To build a production version of the compiler plugin, run ",Object(o.b)("inlineCode",{parentName:"p"},"npm run build"),". In addition to compiling and bundling the TypeScript code, this will also build the ",Object(o.b)("inlineCode",{parentName:"p"},"find-graphql-tags")," CLI tool and copy it into the ",Object(o.b)("inlineCode",{parentName:"p"},"dist")," directory alongside the compiled JavaScript. This tool is needed when running the Relay compiler."),Object(o.b)("p",null,"While developing changes to the compiler plugin, run ",Object(o.b)("inlineCode",{parentName:"p"},"npm start")," to watch for changes and rebuild a development version when you edit sources."),Object(o.b)("p",null,"Running ",Object(o.b)("inlineCode",{parentName:"p"},"npm start")," first cleans the ",Object(o.b)("inlineCode",{parentName:"p"},"dist")," directory, so once it's up and running, you'll also need to run ",Object(o.b)("inlineCode",{parentName:"p"},"npm run prepublishOnly")," to build and copy ",Object(o.b)("inlineCode",{parentName:"p"},"find-graphql-tags")," into the ",Object(o.b)("inlineCode",{parentName:"p"},"dist")," directory in order for the compiler to actually work with your local copy of the plugin."),Object(o.b)("p",null,"The ",Object(o.b)("inlineCode",{parentName:"p"},"RelayTestHelpers")," package and the example apps all include code that is generated by the Relay compiler. If you change the compiler plugin, you should also regenerate this code by running ",Object(o.b)("inlineCode",{parentName:"p"},"npm run relay")," in the root of the ",Object(o.b)("inlineCode",{parentName:"p"},"Relay.swift")," package. If you forget to do this, don't worry: a GitHub action will detect this and automatically commit any necessary changes."),Object(o.b)("p",null,"Working on the compiler plugin (specifically building ",Object(o.b)("inlineCode",{parentName:"p"},"find-graphql-tags"),") requires either Xcode 11.4 or Xcode 11.5, due to the pinned version of SwiftSyntax that we are using. If this is not your default Xcode version, you can set the ",Object(o.b)("inlineCode",{parentName:"p"},"DEVELOPER_DIR")," environment variable when working on the compiler plugin to override it. If you build with the wrong Xcode version, the Relay compiler will fail at runtime."),Object(o.b)("h2",{id:"releasing-a-new-version"},"Releasing a new version"),Object(o.b)("div",{className:"admonition admonition-note alert alert--secondary"},Object(o.b)("div",{parentName:"div",className:"admonition-heading"},Object(o.b)("h5",{parentName:"div"},Object(o.b)("span",{parentName:"h5",className:"admonition-icon"},Object(o.b)("svg",{parentName:"span",xmlns:"http://www.w3.org/2000/svg",width:"14",height:"16",viewBox:"0 0 14 16"},Object(o.b)("path",{parentName:"svg",fillRule:"evenodd",d:"M6.3 5.69a.942.942 0 0 1-.28-.7c0-.28.09-.52.28-.7.19-.18.42-.28.7-.28.28 0 .52.09.7.28.18.19.28.42.28.7 0 .28-.09.52-.28.7a1 1 0 0 1-.7.3c-.28 0-.52-.11-.7-.3zM8 7.99c-.02-.25-.11-.48-.31-.69-.2-.19-.42-.3-.69-.31H6c-.27.02-.48.13-.69.31-.2.2-.3.44-.31.69h1v3c.02.27.11.5.31.69.2.2.42.31.69.31h1c.27 0 .48-.11.69-.31.2-.19.3-.42.31-.69H8V7.98v.01zM7 2.3c-3.14 0-5.7 2.54-5.7 5.68 0 3.14 2.56 5.7 5.7 5.7s5.7-2.55 5.7-5.7c0-3.15-2.56-5.69-5.7-5.69v.01zM7 .98c3.86 0 7 3.14 7 7s-3.14 7-7 7-7-3.12-7-7 3.14-7 7-7z"}))),"note")),Object(o.b)("div",{parentName:"div",className:"admonition-content"},Object(o.b)("p",{parentName:"div"},"This section needs to updated based on the new Docusaurus-based website."))),Object(o.b)("p",null,"This isn't currently something that other contributors besides Matt can do, but it's documented here anyway for completeness."),Object(o.b)("p",null,"Before releasing a new version, prepare a new page for it under ",Object(o.b)("a",{parentName:"p",href:"#"},"Release Notes"),' that is tagged as "Unreleased". You can take your time preparing the notes.'),Object(o.b)("p",null,"Once the notes are ready, the process for releasing a new version is largely automated:"),Object(o.b)("ul",null,Object(o.b)("li",{parentName:"ul"},"Go to the ",Object(o.b)("a",{parentName:"li",href:"https://github.com/mjm/Relay.swift/actions?query=workflow%3ARelease"},"Release"),' action on GitHub and click the "Run worklow" button'),Object(o.b)("li",{parentName:"ul"},"Enter the new version number that is going to be released"),Object(o.b)("li",{parentName:"ul"},"Wait for the action to:",Object(o.b)("ul",{parentName:"li"},Object(o.b)("li",{parentName:"ul"},"Publish the new compiler plugin to npm"),Object(o.b)("li",{parentName:"ul"},"Commit and tag the change under the new version"),Object(o.b)("li",{parentName:"ul"},"Push the tag"))),Object(o.b)("li",{parentName:"ul"},"When the tag is pushed, another action should trigger that creates a new GitHub release for the tag. Edit the release to include a link to the version's release notes page on Notion"),Object(o.b)("li",{parentName:"ul"},'Remove the "Unreleased" tag from the version\'s release notes page'),Object(o.b)("li",{parentName:"ul"},'Set the "Release date" for the page to the current date'),Object(o.b)("li",{parentName:"ul"},"Lock the page so it can't be changed"),Object(o.b)("li",{parentName:"ul"},'Update the "Latest version:" on  ',Object(o.b)("a",{parentName:"li",href:"#"},"Relay.swift")," to point to the new version's page"),Object(o.b)("li",{parentName:"ul"},"Announce it!")))}s.isMDXComponent=!0},154:function(e,t,n){"use strict";n.d(t,"a",(function(){return d})),n.d(t,"b",(function(){return h}));var i=n(0),a=n.n(i);function o(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function r(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var i=Object.getOwnPropertySymbols(e);t&&(i=i.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,i)}return n}function l(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?r(Object(n),!0).forEach((function(t){o(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):r(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function c(e,t){if(null==e)return{};var n,i,a=function(e,t){if(null==e)return{};var n,i,a={},o=Object.keys(e);for(i=0;i<o.length;i++)n=o[i],t.indexOf(n)>=0||(a[n]=e[n]);return a}(e,t);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);for(i=0;i<o.length;i++)n=o[i],t.indexOf(n)>=0||Object.prototype.propertyIsEnumerable.call(e,n)&&(a[n]=e[n])}return a}var p=a.a.createContext({}),s=function(e){var t=a.a.useContext(p),n=t;return e&&(n="function"==typeof e?e(t):l(l({},t),e)),n},d=function(e){var t=s(e.components);return a.a.createElement(p.Provider,{value:t},e.children)},b={inlineCode:"code",wrapper:function(e){var t=e.children;return a.a.createElement(a.a.Fragment,{},t)}},u=a.a.forwardRef((function(e,t){var n=e.components,i=e.mdxType,o=e.originalType,r=e.parentName,p=c(e,["components","mdxType","originalType","parentName"]),d=s(n),u=i,h=d["".concat(r,".").concat(u)]||d[u]||b[u]||o;return n?a.a.createElement(h,l(l({ref:t},p),{},{components:n})):a.a.createElement(h,l({ref:t},p))}));function h(e,t){var n=arguments,i=t&&t.mdxType;if("string"==typeof e||i){var o=n.length,r=new Array(o);r[0]=u;var l={};for(var c in t)hasOwnProperty.call(t,c)&&(l[c]=t[c]);l.originalType=e,l.mdxType="string"==typeof e?e:i,r[1]=l;for(var p=2;p<o;p++)r[p]=n[p];return a.a.createElement.apply(null,r)}return a.a.createElement.apply(null,n)}u.displayName="MDXCreateElement"}}]);