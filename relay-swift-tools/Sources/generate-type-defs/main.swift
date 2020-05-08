import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder

let str = """
{
    "fragment": {
        "argumentDefinitions": [
            {
                "defaultValue": null,
                "kind": "LocalArgument",
                "name": "id",
                "type": "String"
            }
        ],
        "kind": "Fragment",
        "metadata": null,
        "name": "PokemonDetailQuery",
        "selections": [
            {
                "alias": null,
                "args": [
                    {
                        "kind": "Variable",
                        "name": "id",
                        "variableName": "id"
                    }
                ],
                "concreteType": "Pokemon",
                "kind": "LinkedField",
                "name": "pokemon",
                "plural": false,
                "selections": [
                    {
                        "alias": null,
                        "args": null,
                        "kind": "ScalarField",
                        "name": "id",
                        "storageKey": null
                    },
                    {
                        "args": null,
                        "kind": "FragmentSpread",
                        "name": "PokemonDetailInfoSection_pokemon"
                    }
                ],
                "storageKey": null
            }
        ],
        "type": "Query"
    },
    "kind": "Request",
    "operation": {
        "argumentDefinitions": [
            {
                "defaultValue": null,
                "kind": "LocalArgument",
                "name": "id",
                "type": "String"
            }
        ],
        "kind": "Operation",
        "name": "PokemonDetailQuery",
        "selections": [
            {
                "alias": null,
                "args": [
                    {
                        "kind": "Variable",
                        "name": "id",
                        "variableName": "id"
                    }
                ],
                "concreteType": "Pokemon",
                "kind": "LinkedField",
                "name": "pokemon",
                "plural": false,
                "selections": [
                    {
                        "alias": null,
                        "args": null,
                        "kind": "ScalarField",
                        "name": "id",
                        "storageKey": null
                    },
                    {
                        "alias": null,
                        "args": null,
                        "kind": "ScalarField",
                        "name": "name",
                        "storageKey": null
                    },
                    {
                        "alias": null,
                        "args": null,
                        "kind": "ScalarField",
                        "name": "number",
                        "storageKey": null
                    },
                    {
                        "alias": null,
                        "args": null,
                        "kind": "ScalarField",
                        "name": "classification",
                        "storageKey": null
                    }
                ],
                "storageKey": null
            }
        ]
    },
    "params": {
        "id": null,
        "metadata": {},
        "name": "PokemonDetailQuery",
        "operationKind": "query",
        "text": "query PokemonDetailQuery(\\n  $id: String\\n) {\\n  pokemon(id: $id) {\\n    id\\n    ...PokemonDetailInfoSection_pokemon\\n  }\\n}\\n\\nfragment PokemonDetailInfoSection_pokemon on Pokemon {\\n  name\\n  number\\n  classification\\n}\\n"
    },
"schemaTypes": {
"ID": {
    "fields": {}
},
"String": {
    "fields": {}
},
"Boolean": {
    "fields": {}
},
"Float": {
    "fields": {}
},
"Int": {
    "fields": {}
},
"Attack": {
    "fields": {
        "name": {
            "type": "String",
            "rawType": "String",
            "isNonNull": false,
            "isPlural": false,
            "isNonNullItems": false
        },
        "type": {
            "type": "String",
            "rawType": "String",
            "isNonNull": false,
            "isPlural": false,
            "isNonNullItems": false
        },
        "damage": {
            "type": "Int",
            "rawType": "Int",
            "isNonNull": false,
            "isPlural": false,
            "isNonNullItems": false
        }
    }
},
"Pokemon": {
    "fields": {
        "id": {
            "type": "ID!",
            "rawType": "ID",
            "isNonNull": true,
            "isPlural": false,
            "isNonNullItems": false
        },
        "number": {
            "type": "String",
            "rawType": "String",
            "isNonNull": false,
            "isPlural": false,
            "isNonNullItems": false
        },
        "name": {
            "type": "String",
            "rawType": "String",
            "isNonNull": false,
            "isPlural": false,
            "isNonNullItems": false
        },
        "weight": {
            "type": "PokemonDimension",
            "rawType": "PokemonDimension",
            "isNonNull": false,
            "isPlural": false,
            "isNonNullItems": false
        },
        "height": {
            "type": "PokemonDimension",
            "rawType": "PokemonDimension",
            "isNonNull": false,
            "isPlural": false,
            "isNonNullItems": false
        },
        "classification": {
            "type": "String",
            "rawType": "String",
            "isNonNull": false,
            "isPlural": false,
            "isNonNullItems": false
        },
        "types": {
            "type": "[String]",
            "rawType": "String",
            "isNonNull": false,
            "isPlural": true,
            "isNonNullItems": false
        },
        "resistant": {
            "type": "[String]",
            "rawType": "String",
            "isNonNull": false,
            "isPlural": true,
            "isNonNullItems": false
        },
        "attacks": {
            "type": "PokemonAttack",
            "rawType": "PokemonAttack",
            "isNonNull": false,
            "isPlural": false,
            "isNonNullItems": false
        },
        "weaknesses": {
            "type": "[String]",
            "rawType": "String",
            "isNonNull": false,
            "isPlural": true,
            "isNonNullItems": false
        },
        "fleeRate": {
            "type": "Float",
            "rawType": "Float",
            "isNonNull": false,
            "isPlural": false,
            "isNonNullItems": false
        },
        "maxCP": {
            "type": "Int",
            "rawType": "Int",
            "isNonNull": false,
            "isPlural": false,
            "isNonNullItems": false
        },
        "evolutions": {
            "type": "[Pokemon]",
            "rawType": "Pokemon",
            "isNonNull": false,
            "isPlural": true,
            "isNonNullItems": false
        },
        "evolutionRequirements": {
            "type": "PokemonEvolutionRequirement",
            "rawType": "PokemonEvolutionRequirement",
            "isNonNull": false,
            "isPlural": false,
            "isNonNullItems": false
        },
        "maxHP": {
            "type": "Int",
            "rawType": "Int",
            "isNonNull": false,
            "isPlural": false,
            "isNonNullItems": false
        },
        "image": {
            "type": "String",
            "rawType": "String",
            "isNonNull": false,
            "isPlural": false,
            "isNonNullItems": false
        }
    }
},
"PokemonAttack": {
    "fields": {
        "fast": {
            "type": "[Attack]",
            "rawType": "Attack",
            "isNonNull": false,
            "isPlural": true,
            "isNonNullItems": false
        },
        "special": {
            "type": "[Attack]",
            "rawType": "Attack",
            "isNonNull": false,
            "isPlural": true,
            "isNonNullItems": false
        }
    }
},
"PokemonDimension": {
    "fields": {
        "minimum": {
            "type": "String",
            "rawType": "String",
            "isNonNull": false,
            "isPlural": false,
            "isNonNullItems": false
        },
        "maximum": {
            "type": "String",
            "rawType": "String",
            "isNonNull": false,
            "isPlural": false,
            "isNonNullItems": false
        }
    }
},
"PokemonEvolutionRequirement": {
    "fields": {
        "amount": {
            "type": "Int",
            "rawType": "Int",
            "isNonNull": false,
            "isPlural": false,
            "isNonNullItems": false
        },
        "name": {
            "type": "String",
            "rawType": "String",
            "isNonNull": false,
            "isPlural": false,
            "isNonNullItems": false
        }
    }
},
"Query": {
    "fields": {
        "query": {
            "type": "Query",
            "rawType": "Query",
            "isNonNull": false,
            "isPlural": false,
            "isNonNullItems": false
        },
        "pokemons": {
            "type": "[Pokemon]",
            "rawType": "Pokemon",
            "isNonNull": false,
            "isPlural": true,
            "isNonNullItems": false
        },
        "pokemon": {
            "type": "Pokemon",
            "rawType": "Pokemon",
            "isNonNull": false,
            "isPlural": false,
            "isNonNullItems": false
        }
    }
}
}
}
"""
let data = str.data(using: .utf8)!

//let data = FileHandle.standardInput.readDataToEndOfFile()
let parsedData = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]

SchemaType.loadAll(parsedData["schemaTypes"] as! [String: Any])

let kind = parsedData["kind"] as! String
var fragment = parsedData
if kind == "Request" {
    fragment = parsedData["fragment"] as! [String: Any]
}
let name = fragment["name"] as! String

print(ImportDeclSyntax { builder in
    builder.useImportTok(SyntaxFactory.makeImportKeyword(trailingTrivia: .spaces(1)))
    builder.addPathComponent(AccessPathComponentSyntax { builder in
        builder.useName(SyntaxFactory.makeIdentifier("Relay"))
    })
})
print("")

print(StructDeclSyntax { builder in
    builder.useStructKeyword(SyntaxFactory.makeStructKeyword(trailingTrivia: .spaces(1)))
    builder.useIdentifier(SyntaxFactory.makeIdentifier(name))
    builder.useInheritanceClause(TypeInheritanceClauseSyntax { builder in
        builder.useColon(SyntaxFactory.makeColonToken(trailingTrivia: .spaces(1)))
        builder.addInheritedType(InheritedTypeSyntax { builder in
            if kind == "Root" {
                builder.useTypeName(SyntaxFactory.makeTypeIdentifier("Operation"))
            } else {
                builder.useTypeName(SyntaxFactory.makeTypeIdentifier("Fragment"))
            }
        })
    })
    builder.useMembers(MemberDeclBlockSyntax { builder in
        builder.useLeftBrace(SyntaxFactory.makeLeftBraceToken(leadingTrivia: .spaces(1), trailingTrivia: .newlines(1)))

        builder.addMember(MemberDeclListItemSyntax { builder in
            builder.useDecl(DeclSyntax(VariableDeclSyntax { builder in
                builder.useLetOrVarKeyword(SyntaxFactory.makeVarKeyword(leadingTrivia: .spaces(4), trailingTrivia: .spaces(1)))
                builder.addBinding(PatternBindingSyntax { builder in
                    builder.usePattern(PatternSyntax(IdentifierPatternSyntax { builder in
                        builder.useIdentifier(SyntaxFactory.makeIdentifier("node"))
                    }))
                    builder.useTypeAnnotation(TypeAnnotationSyntax { builder in
                        builder.useColon(SyntaxFactory.makeColonToken(trailingTrivia: .spaces(1)))
                        builder.useType(SyntaxFactory.makeTypeIdentifier(kind == "Request" ? "ConcreteRequest" : "ReaderFragment", trailingTrivia: .spaces(1)))
                    })
                    builder.useAccessor(Syntax(CodeBlockSyntax { builder in
                        builder.useLeftBrace(SyntaxFactory.makeLeftBraceToken(trailingTrivia: .newlines(1)))

                        builder.addStatement(CodeBlockItemSyntax { builder in
                            builder.useItem(Syntax(ReturnStmtSyntax { builder in
                                builder.useReturnKeyword(SyntaxFactory.makeReturnKeyword(leadingTrivia: .spaces(8), trailingTrivia: .spaces(1)))
                                builder.useExpression(kind == "Request" ? makeConcreteRequestExpr(input: parsedData) : makeReaderFragmentExpr(node: parsedData))
                            }))
                        })

                        builder.useRightBrace(SyntaxFactory.makeRightBraceToken(leadingTrivia: .newlines(1) + .spaces(4)))
                    }))
                })
            }.withTrailingTrivia(.newlines(2))))
        })

        builder.addMember(MemberDeclListItemSyntax { builder in
            builder.useDecl(makeReadableStruct(node: fragment, name: "Data", indent: 4))
        })

        builder.useRightBrace(SyntaxFactory.makeRightBraceToken(leadingTrivia: .newlines(1)))
    })
})
