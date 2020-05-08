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
    }
}
"""
let data = str.data(using: .utf8)!

//let data = FileHandle.standardInput.readDataToEndOfFile()
let parsedData = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]

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
            }.withTrailingTrivia(.newlines(1))))
        })

        builder.useRightBrace(SyntaxFactory.makeRightBraceToken())
    })
})
