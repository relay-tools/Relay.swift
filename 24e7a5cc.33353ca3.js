(window.webpackJsonp=window.webpackJsonp||[]).push([[13],{154:function(e,r,t){"use strict";t.d(r,"a",(function(){return b})),t.d(r,"b",(function(){return f}));var n=t(0),a=t.n(n);function i(e,r,t){return r in e?Object.defineProperty(e,r,{value:t,enumerable:!0,configurable:!0,writable:!0}):e[r]=t,e}function o(e,r){var t=Object.keys(e);if(Object.getOwnPropertySymbols){var n=Object.getOwnPropertySymbols(e);r&&(n=n.filter((function(r){return Object.getOwnPropertyDescriptor(e,r).enumerable}))),t.push.apply(t,n)}return t}function c(e){for(var r=1;r<arguments.length;r++){var t=null!=arguments[r]?arguments[r]:{};r%2?o(Object(t),!0).forEach((function(r){i(e,r,t[r])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(t)):o(Object(t)).forEach((function(r){Object.defineProperty(e,r,Object.getOwnPropertyDescriptor(t,r))}))}return e}function d(e,r){if(null==e)return{};var t,n,a=function(e,r){if(null==e)return{};var t,n,a={},i=Object.keys(e);for(n=0;n<i.length;n++)t=i[n],r.indexOf(t)>=0||(a[t]=e[t]);return a}(e,r);if(Object.getOwnPropertySymbols){var i=Object.getOwnPropertySymbols(e);for(n=0;n<i.length;n++)t=i[n],r.indexOf(t)>=0||Object.prototype.propertyIsEnumerable.call(e,t)&&(a[t]=e[t])}return a}var l=a.a.createContext({}),s=function(e){var r=a.a.useContext(l),t=r;return e&&(t="function"==typeof e?e(r):c(c({},r),e)),t},b=function(e){var r=s(e.components);return a.a.createElement(l.Provider,{value:r},e.children)},p={inlineCode:"code",wrapper:function(e){var r=e.children;return a.a.createElement(a.a.Fragment,{},r)}},u=a.a.forwardRef((function(e,r){var t=e.components,n=e.mdxType,i=e.originalType,o=e.parentName,l=d(e,["components","mdxType","originalType","parentName"]),b=s(t),u=n,f=b["".concat(o,".").concat(u)]||b[u]||p[u]||i;return t?a.a.createElement(f,c(c({ref:r},l),{},{components:t})):a.a.createElement(f,c({ref:r},l))}));function f(e,r){var t=arguments,n=r&&r.mdxType;if("string"==typeof e||n){var i=t.length,o=new Array(i);o[0]=u;var c={};for(var d in r)hasOwnProperty.call(r,d)&&(c[d]=r[d]);c.originalType=e,c.mdxType="string"==typeof e?e:n,o[1]=c;for(var l=2;l<i;l++)o[l]=t[l];return a.a.createElement.apply(null,o)}return a.a.createElement.apply(null,t)}u.displayName="MDXCreateElement"},78:function(e,r,t){"use strict";t.r(r),t.d(r,"frontMatter",(function(){return o})),t.d(r,"metadata",(function(){return c})),t.d(r,"toc",(function(){return d})),t.d(r,"default",(function(){return s}));var n=t(3),a=t(7),i=(t(0),t(154)),o={title:"RecordProxy"},c={unversionedId:"api/record-proxy",id:"version-1.0.0/api/record-proxy",isDocsHomePage:!1,title:"RecordProxy",description:"`swift",source:"@site/versioned_docs/version-1.0.0/api/record-proxy.md",slug:"/api/record-proxy",permalink:"/Relay.swift/docs/api/record-proxy",editUrl:"https://github.com/relay-tools/Relay.swift/edit/main/website/versioned_docs/version-1.0.0/api/record-proxy.md",version:"1.0.0",sidebar:"version-1.0.0/docs",previous:{title:"RecordSourceSelectorProxy",permalink:"/Relay.swift/docs/api/record-source-selector-proxy"},next:{title:"ConnectionHandler",permalink:"/Relay.swift/docs/api/connection-handler"}},d=[{value:"Reading record metadata",id:"reading-record-metadata",children:[{value:"<code>dataID</code>",id:"dataid",children:[]},{value:"<code>typeName</code>",id:"typename",children:[]}]},{value:"Accessing fields from a record",id:"accessing-fields-from-a-record",children:[{value:"<code>subscript(_:args:)</code>",id:"subscript_args",children:[]}]},{value:"Accessing linked records",id:"accessing-linked-records",children:[{value:"<code>getLinkedRecord(_:args:)</code> &amp; <code>setLinkedRecord(_:args:record:)</code>",id:"getlinkedrecord_args--setlinkedrecord_argsrecord",children:[]},{value:"<code>getOrCreateLinkedRecord(_:typeName:args:)</code>",id:"getorcreatelinkedrecord_typenameargs",children:[]}]},{value:"Accessing lists of linked records",id:"accessing-lists-of-linked-records",children:[{value:"<code>getLinkedRecords(_:args:)</code> &amp; <code>setLinkedRecords(_:args:records:)</code>",id:"getlinkedrecords_args--setlinkedrecords_argsrecords",children:[]}]},{value:"Copying between records",id:"copying-between-records",children:[{value:"<code>copyFields(from:)</code>",id:"copyfieldsfrom",children:[]}]},{value:"Invalidation",id:"invalidation",children:[{value:"<code>invalidateRecord()</code>",id:"invalidaterecord",children:[]}]}],l={toc:d};function s(e){var r=e.components,t=Object(a.a)(e,["components"]);return Object(i.b)("wrapper",Object(n.a)({},l,t,{components:r,mdxType:"MDXLayout"}),Object(i.b)("pre",null,Object(i.b)("code",{parentName:"pre",className:"language-swift"},"protocol RecordProxy\n")),Object(i.b)("p",null,"A ",Object(i.b)("inlineCode",{parentName:"p"},"RecordProxy")," provides API reading and updating the fields of a particular record in the Relay store. A ",Object(i.b)("inlineCode",{parentName:"p"},"RecordProxy")," can be obtained from a ",Object(i.b)("a",{parentName:"p",href:"/Relay.swift/docs/api/record-source-selector-proxy"},"RecordSourceSelectorProxy")," or another ",Object(i.b)("inlineCode",{parentName:"p"},"RecordProxy")," when updating the store after a mutation."),Object(i.b)("h2",{id:"reading-record-metadata"},"Reading record metadata"),Object(i.b)("h3",{id:"dataid"},Object(i.b)("inlineCode",{parentName:"h3"},"dataID")),Object(i.b)("pre",null,Object(i.b)("code",{parentName:"pre",className:"language-swift"},"var dataID: DataID { get }\n")),Object(i.b)("p",null,"Returns the ID of the record."),Object(i.b)("p",null,"All records have a unique ID in the store. If the record has an ",Object(i.b)("inlineCode",{parentName:"p"},"id")," field, that value will be used as the ID. Otherwise, Relay will choose a client-side ID and use that."),Object(i.b)("p",null,"Because Relay uses that ",Object(i.b)("inlineCode",{parentName:"p"},"id")," field as a store-wide ID, it's important that you don't use the same IDs for two different values of different types. Your IDs must be globally unique, not just unique within a particular type. One way to do this is to include the type name or an abbreviation of it as part of the ID."),Object(i.b)("h3",{id:"typename"},Object(i.b)("inlineCode",{parentName:"h3"},"typeName")),Object(i.b)("pre",null,Object(i.b)("code",{parentName:"pre",className:"language-swift"},"var typeName: String { get }\n")),Object(i.b)("p",null,"Returns the name of the schema type for the record."),Object(i.b)("p",null,"Every record in the store belongs to one of the types defined in your GraphQL schema."),Object(i.b)("h2",{id:"accessing-fields-from-a-record"},"Accessing fields from a record"),Object(i.b)("h3",{id:"subscript_args"},Object(i.b)("inlineCode",{parentName:"h3"},"subscript(_:args:)")),Object(i.b)("pre",null,Object(i.b)("code",{parentName:"pre",className:"language-swift"},"subscript(\n  _ name: String,\n  args args: VariableDataConvertible? = nil\n) -> Any? { get set }\n")),Object(i.b)("p",null,"You can use subscripts to read and write scalar fields of a record."),Object(i.b)("p",null,"If the field has arguments, those should be passed to the subscript as well. This can be an ordinary Swift dictionary:"),Object(i.b)("pre",null,Object(i.b)("code",{parentName:"pre",className:"language-swift"},'record["name", args: ["language": "en"]] = "hello world"\n')),Object(i.b)("h2",{id:"accessing-linked-records"},"Accessing linked records"),Object(i.b)("h3",{id:"getlinkedrecord_args--setlinkedrecord_argsrecord"},Object(i.b)("inlineCode",{parentName:"h3"},"getLinkedRecord(_:args:)")," & ",Object(i.b)("inlineCode",{parentName:"h3"},"setLinkedRecord(_:args:record:)")),Object(i.b)("pre",null,Object(i.b)("code",{parentName:"pre",className:"language-swift"},"func getLinkedRecord(\n  _ name: String,\n  args: VariableDataConvertible? = nil\n) -> RecordProxy?\n\nmutating func setLinkedRecord(\n  _ name: String,\n  args: VariableDataConvertible? = nil,\n  record: RecordProxy\n)\n")),Object(i.b)("p",null,"To read and write fields where the value is another record, use ",Object(i.b)("inlineCode",{parentName:"p"},"getLinkedRecord")," and ",Object(i.b)("inlineCode",{parentName:"p"},"setLinkedRecord"),". Like scalar field subscripts, they take an options ",Object(i.b)("inlineCode",{parentName:"p"},"args")," parameter for any arguments passed to the field."),Object(i.b)("p",null,"Note that ",Object(i.b)("inlineCode",{parentName:"p"},"setLinkedRecord")," takes a non-optional record parameter. If you want to set a field for a linked record to ",Object(i.b)("inlineCode",{parentName:"p"},"nil"),", use the subscript like you would a scalar field."),Object(i.b)("h3",{id:"getorcreatelinkedrecord_typenameargs"},Object(i.b)("inlineCode",{parentName:"h3"},"getOrCreateLinkedRecord(_:typeName:args:)")),Object(i.b)("pre",null,Object(i.b)("code",{parentName:"pre",className:"language-swift"},"mutating func getOrCreateLinkedRecord(\n  _ name: String,\n  typeName: String,\n  args: VariableDataConvertible?\n) -> RecordProxy\n")),Object(i.b)("p",null,'A convenience function is available to "upsert" a record for a linked field. ',Object(i.b)("inlineCode",{parentName:"p"},"getOrCreateLinkedRecord")," will use an existing record for the field if one is already present, or it will create an empty one if there isn't one set."),Object(i.b)("p",null,"If a record is created, it will have a client-side ID chosen for it by Relay. If you need the ID to be something specific, use the ",Object(i.b)("inlineCode",{parentName:"p"},"create")," method on ",Object(i.b)("a",{parentName:"p",href:"/Relay.swift/docs/api/record-source-selector-proxy"},"RecordSourceSelectorProxy")," to create the record, then call ",Object(i.b)("inlineCode",{parentName:"p"},"setLinkedRecord")," to set the value for the field."),Object(i.b)("h2",{id:"accessing-lists-of-linked-records"},"Accessing lists of linked records"),Object(i.b)("h3",{id:"getlinkedrecords_args--setlinkedrecords_argsrecords"},Object(i.b)("inlineCode",{parentName:"h3"},"getLinkedRecords(_:args:)")," & ",Object(i.b)("inlineCode",{parentName:"h3"},"setLinkedRecords(_:args:records:)")),Object(i.b)("pre",null,Object(i.b)("code",{parentName:"pre",className:"language-swift"},"func getLinkedRecords(\n  _ name: String,\n  args: VariableDataConvertible?\n) -> [RecordProxy?]?\n\nmutating func setLinkedRecords(\n  _ name: String,\n  args: VariableDataConvertible?,\n  records: [RecordProxy?]\n)\n")),Object(i.b)("p",null,"To read and write fields where the value is a list of records, use ",Object(i.b)("inlineCode",{parentName:"p"},"getLinkedRecords")," and ",Object(i.b)("inlineCode",{parentName:"p"},"setLinkedRecords"),". These behave very similarly to their singular equivalents."),Object(i.b)("h2",{id:"copying-between-records"},"Copying between records"),Object(i.b)("h3",{id:"copyfieldsfrom"},Object(i.b)("inlineCode",{parentName:"h3"},"copyFields(from:)")),Object(i.b)("pre",null,Object(i.b)("code",{parentName:"pre",className:"language-swift"},"mutating func copyFields(from record: RecordProxy)\n")),Object(i.b)("p",null,"Copies all of the fields from ",Object(i.b)("inlineCode",{parentName:"p"},"record")," into ",Object(i.b)("inlineCode",{parentName:"p"},"self"),"."),Object(i.b)("p",null,"Any fields not present in ",Object(i.b)("inlineCode",{parentName:"p"},"record")," will be unchanged in ",Object(i.b)("inlineCode",{parentName:"p"},"self"),"."),Object(i.b)("p",null,"Note that this copies all fields, including linked records."),Object(i.b)("h2",{id:"invalidation"},"Invalidation"),Object(i.b)("h3",{id:"invalidaterecord"},Object(i.b)("inlineCode",{parentName:"h3"},"invalidateRecord()")),Object(i.b)("pre",null,Object(i.b)("code",{parentName:"pre",className:"language-swift"},"mutating func invalidateRecord()\n")),Object(i.b)("p",null,"Marks the record as having invalid data that needs to be refreshed."),Object(i.b)("p",null,"If a record is invalidated, it will still exist in the store, but when a ",Object(i.b)("a",{parentName:"p",href:"/Relay.swift/docs/api/query"},"@Query")," is rendered with a ",Object(i.b)("inlineCode",{parentName:"p"},".storeOrNetwork")," or ",Object(i.b)("inlineCode",{parentName:"p"},".storeAndNetwork")," fetch policy, those records will not be considered valid and will be ignored, requiring a network request to get the latest data. You can use this to ensure your UI doesn't display data that is known to be stale."))}s.isMDXComponent=!0}}]);