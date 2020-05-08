import SwiftSyntax

func makeVariablesStruct(node: [String: Any]) -> DeclSyntax {
    guard let args = node["argumentDefinitions"] as? [[String: Any]] else {
        preconditionFailure("Cannot create variables struct for a node without argument definitions")
    }

    let variables = args.map { arg in
        Variable(
            name: arg["name"] as! String,
            type: SchemaType.byName[arg["type"] as! String]!.syntax(nullable: true),
            defaultValue: arg["defaultValue"]!
        )
    }

    return DeclSyntax(StructDeclSyntax { builder in
        builder.useStructKeyword(SyntaxFactory.makeStructKeyword(leadingTrivia: .spaces(4), trailingTrivia: .spaces(1)))
        builder.useIdentifier(SyntaxFactory.makeIdentifier("Variables"))
        builder.useInheritanceClause(TypeInheritanceClauseSyntax { builder in
            builder.useColon(SyntaxFactory.makeColonToken(trailingTrivia: .spaces(1)))
            builder.addInheritedType(InheritedTypeSyntax { builder in
                builder.useTypeName(SyntaxFactory.makeTypeIdentifier("Relay.Variables"))
            })
        }.withTrailingTrivia(.spaces(1)))

        builder.useMembers(MemberDeclBlockSyntax { builder in
            builder.useLeftBrace(SyntaxFactory.makeLeftBraceToken(trailingTrivia: .newlines(1)))

            for variable in variables {
                builder.addMember(MemberDeclListItemSyntax { builder in
                    builder.useDecl(makeVariableDecl(variable: variable, indent: 8))
                })
            }

            builder.addMember(MemberDeclListItemSyntax { builder in
                builder.useDecl(makeAsDictionaryDecl(variables: variables, indent: 8))
            })

//            builder.addMember(MemberDeclListItemSyntax { builder in
//                builder.useDecl(makeInitFromSelectorDataDecl(selectionFields: selectionFields, indent: indent + 4)
//                    .withLeadingTrivia(.newlines(1) + .spaces(indent + 4)))
//            })
//
//            let linkedFields = selectionFields.filter { $0.isLinked }
//
//            for field in linkedFields {
//                builder.addMember(MemberDeclListItemSyntax { builder in
//                    builder.useDecl(makeReadableStruct(node: field.node, name: field.schemaField!.type, indent: indent + 4)
//                        .withLeadingTrivia(.newlines(1) + .spaces(indent + 4)))
//                })
//            }

            builder.useRightBrace(SyntaxFactory.makeRightBraceToken(leadingTrivia: .newlines(1) + .spaces(4)))
        })
    })
}

struct Variable {
    var name: String
    var type: TypeSyntax
    var defaultValue: Any
}

private func makeVariableDecl(variable: Variable, indent: Int) -> DeclSyntax {
    return DeclSyntax(VariableDeclSyntax { builder in
        builder.useLetOrVarKeyword(SyntaxFactory.makeVarKeyword(leadingTrivia: .spaces(indent), trailingTrivia: .spaces(1)))
        builder.addBinding(PatternBindingSyntax { builder in
            builder.usePattern(PatternSyntax(IdentifierPatternSyntax { builder in
                builder.useIdentifier(SyntaxFactory.makeIdentifier(variable.name))
            }))
            builder.useTypeAnnotation(TypeAnnotationSyntax { builder in
                builder.useColon(SyntaxFactory.makeColonToken(trailingTrivia: .spaces(1)))
                builder.useType(variable.type)
            })
        }.withTrailingTrivia(.newlines(2)))

        // TODO default value
    })
}

private func makeAsDictionaryDecl(variables: [Variable], indent: Int) -> DeclSyntax {
    DeclSyntax(VariableDeclSyntax { builder in
        builder.useLetOrVarKeyword(SyntaxFactory.makeVarKeyword(leadingTrivia: .spaces(indent), trailingTrivia: .spaces(1)))
        builder.addBinding(PatternBindingSyntax { builder in
            builder.usePattern(PatternSyntax(IdentifierPatternSyntax { builder in
                builder.useIdentifier(SyntaxFactory.makeIdentifier("asDictionary"))
            }))
            builder.useTypeAnnotation(TypeAnnotationSyntax { builder in
                builder.useColon(SyntaxFactory.makeColonToken(trailingTrivia: .spaces(1)))
                builder.useType(SyntaxFactory.makeTypeIdentifier("[String: Any]", trailingTrivia: .spaces(1)))
            })
            builder.useAccessor(Syntax(CodeBlockSyntax { builder in
                builder.useLeftBrace(SyntaxFactory.makeLeftBraceToken(trailingTrivia: .newlines(1)))

                builder.addStatement(CodeBlockItemSyntax { builder in
                    builder.useItem(Syntax(DictionaryExprSyntax { builder in
                        builder.useLeftSquare(SyntaxFactory.makeLeftSquareBracketToken(leadingTrivia: .spaces(indent + 4), trailingTrivia: .newlines(1)))

                        builder.useContent(Syntax(SyntaxFactory.makeDictionaryElementList(variables.map { variable in
                            DictionaryElementSyntax { builder in
                                builder.useKeyExpression(stringLiteral(variable.name).withLeadingTrivia(.spaces(indent + 8)))
                                builder.useColon(SyntaxFactory.makeColonToken(trailingTrivia: .spaces(1)))
                                builder.useValueExpression(ExprSyntax(SequenceExprSyntax { builder in
                                    builder.addElement(ExprSyntax(IdentifierExprSyntax { builder in
                                        builder.useIdentifier(SyntaxFactory.makeIdentifier(variable.name, trailingTrivia: .spaces(1)))
                                    }))
                                    builder.addElement(ExprSyntax(AsExprSyntax { builder in
                                        builder.useAsTok(SyntaxFactory.makeAsKeyword(trailingTrivia: .spaces(1)))
                                        builder.useTypeName(SyntaxFactory.makeTypeIdentifier("Any"))
                                    }))
                                }))
                                builder.useTrailingComma(SyntaxFactory.makeCommaToken(trailingTrivia: .newlines(1)))
                            }
                        })))

                        builder.useRightSquare(SyntaxFactory.makeRightSquareBracketToken(leadingTrivia: .spaces(indent + 4)))
                    }))
                })

                builder.useRightBrace(SyntaxFactory.makeRightBraceToken(leadingTrivia: .newlines(1) + .spaces(indent)))
            }))
        })
    })
}
