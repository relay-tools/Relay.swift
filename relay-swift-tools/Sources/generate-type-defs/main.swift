import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder

let handle: FileHandle
let filePath = ProcessInfo.processInfo.arguments[1]

if filePath == "-" {
    handle = .standardInput
} else {
    handle = FileHandle(forReadingAtPath: filePath)!
}

let data = handle.readDataToEndOfFile()
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
            if kind == "Request" {
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
                                builder.useExpression(kind == "Request" ? makeConcreteRequestExpr(input: parsedData) : makeReaderFragmentExpr(node: parsedData, indent: 8))
                            }))
                        })

                        builder.useRightBrace(SyntaxFactory.makeRightBraceToken(leadingTrivia: .newlines(1) + .spaces(4)))
                    }))
                })
            }.withTrailingTrivia(.newlines(2))))
        })

        if kind == "Fragment" {
            builder.addMember(MemberDeclListItemSyntax { builder in
                builder.useDecl(makeGetFragmentPointerFuncDecl(name: name))
            }.withTrailingTrivia(.newlines(2)))
        }

        if let operation = parsedData["operation"] as? [String: Any] {
            builder.addMember(MemberDeclListItemSyntax { builder in
                builder.useDecl(makeVariablesStruct(node: operation))
            }.withTrailingTrivia(.newlines(2)))
        }

        builder.addMember(MemberDeclListItemSyntax { builder in
            builder.useDecl(makeReadableStruct(node: fragment, name: "Data", indent: 4))
        })

        builder.useRightBrace(SyntaxFactory.makeRightBraceToken(leadingTrivia: .newlines(1)))
    })
})

if kind == "Fragment" {
    print("")
    print(makeFragmentProtocolDecl(name: name))
}
