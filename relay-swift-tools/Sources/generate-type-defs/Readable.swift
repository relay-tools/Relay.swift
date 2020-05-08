import SwiftSyntax

func makeReadableStruct(node: [String: Any], name: String, indent: Int) -> DeclSyntax {
    guard let selections = node["selections"] as? [[String: Any]] else {
        preconditionFailure("Cannot create readable struct for a node without selections")
    }

    let fragmentNames = selections
        .filter { ($0["kind"] as! String) == "FragmentSpread" }
        .compactMap { $0["name"] as? String }

    let selectionFields = makeFields(node: node, selections: selections)

    return DeclSyntax(StructDeclSyntax { builder in
        builder.useStructKeyword(SyntaxFactory.makeStructKeyword(leadingTrivia: .spaces(indent), trailingTrivia: .spaces(1)))
        builder.useIdentifier(SyntaxFactory.makeIdentifier(name))
        builder.useInheritanceClause(TypeInheritanceClauseSyntax { builder in
            builder.useColon(SyntaxFactory.makeColonToken(trailingTrivia: .spaces(1)))

            let typeNames = ["Readable"] + fragmentNames.map { "\($0)_Key" }

            for (i, typeName) in typeNames.enumerated() {
                builder.addInheritedType(InheritedTypeSyntax { builder in
                    builder.useTypeName(SyntaxFactory.makeTypeIdentifier(typeName))
                    if i < typeNames.count - 1 {
                        builder.useTrailingComma(SyntaxFactory.makeCommaToken(trailingTrivia: .spaces(1)))
                    }
                })
            }
        }.withTrailingTrivia(.spaces(1)))

        builder.useMembers(MemberDeclBlockSyntax { builder in
            builder.useLeftBrace(SyntaxFactory.makeLeftBraceToken(trailingTrivia: .newlines(1)))

            for field in selectionFields {
                builder.addMember(MemberDeclListItemSyntax { builder in
                    builder.useDecl(makeSelectionVariableDecl(selectionField: field, indent: indent + 4))
                })
            }

            builder.addMember(MemberDeclListItemSyntax { builder in
                builder.useDecl(makeInitFromSelectorDataDecl(selectionFields: selectionFields, indent: indent + 4)
                    .withLeadingTrivia(.newlines(1) + .spaces(indent + 4)))
            })

            let linkedFields = selectionFields.filter { $0.isLinked }

            for field in linkedFields {
                builder.addMember(MemberDeclListItemSyntax { builder in
                    builder.useDecl(makeReadableStruct(node: field.node, name: field.schemaField!.type, indent: indent + 4)
                        .withLeadingTrivia(.newlines(1) + .spaces(indent + 4)))
                })
            }

            builder.useRightBrace(SyntaxFactory.makeRightBraceToken(leadingTrivia: .newlines(1) + .spaces(indent)))
        })
    })
}

struct SelectionField {
    var node: [String: Any]
    var name: String
    var type: TypeSyntax
    var schemaField: SchemaField?
    var kind: String

    var isFragment: Bool {
        kind == "FragmentSpread"
    }

    var isLinked: Bool {
        kind == "LinkedField"
    }
}

private func makeFields(node: [String: Any], selections: [[String: Any]]) -> [SelectionField] {
    let parentType = SchemaType.byName[(node["type"] ?? node["concreteType"]) as! String]!

    return selections.map { selection in
        let kind = selection["kind"] as! String
        let name = selection["name"] as! String
        var propertyName = name

        if let alias = selection["alias"] as? String {
            propertyName = alias
        }

        var schemaField: SchemaField?
        var typeSyntax: TypeSyntax
        if kind == "ScalarField" || kind == "LinkedField" {
            schemaField = parentType.fields[name]
            typeSyntax = schemaField!.asTypeSyntax
        } else if kind == "FragmentSpread" {
            propertyName = "fragment_\(name)"
            typeSyntax = SyntaxFactory.makeTypeIdentifier("FragmentPointer")
        } else {
            fatalError()
        }

        return SelectionField(node: selection, name: propertyName, type: typeSyntax, schemaField: schemaField, kind: kind)
    }
}

private func makeSelectionVariableDecl(selectionField: SelectionField, indent: Int) -> DeclSyntax {
    return DeclSyntax(VariableDeclSyntax { builder in
        builder.useLetOrVarKeyword(SyntaxFactory.makeVarKeyword(leadingTrivia: .spaces(indent), trailingTrivia: .spaces(1)))
        builder.addBinding(PatternBindingSyntax { builder in
            builder.usePattern(PatternSyntax(IdentifierPatternSyntax { builder in
                builder.useIdentifier(SyntaxFactory.makeIdentifier(selectionField.name))
            }))
            builder.useTypeAnnotation(TypeAnnotationSyntax { builder in
                builder.useColon(SyntaxFactory.makeColonToken(trailingTrivia: .spaces(1)))
                builder.useType(selectionField.type)
            })
        }.withTrailingTrivia(.newlines(1)))
    })
}

private func makeInitFromSelectorDataDecl(selectionFields: [SelectionField], indent: Int) -> DeclSyntax {
    return DeclSyntax(InitializerDeclSyntax { builder in
        builder.useInitKeyword(SyntaxFactory.makeInitKeyword(leadingTrivia: .spaces(indent)))
        builder.useParameters(ParameterClauseSyntax { builder in
            builder.useLeftParen(SyntaxFactory.makeLeftParenToken())
            builder.addParameter(FunctionParameterSyntax { builder in
                builder.useFirstName(SyntaxFactory.makeIdentifier("from", trailingTrivia: .spaces(1)))
                builder.useSecondName(SyntaxFactory.makeIdentifier("data"))
                builder.useColon(SyntaxFactory.makeColonToken(trailingTrivia: .spaces(1)))
                builder.useType(SyntaxFactory.makeTypeIdentifier("SelectorData"))
            })
            builder.useRightParen(SyntaxFactory.makeRightParenToken(trailingTrivia: .spaces(1)))
        })
        builder.useBody(CodeBlockSyntax { builder in
            builder.useLeftBrace(SyntaxFactory.makeLeftBraceToken(trailingTrivia: .newlines(1)))

            for field in selectionFields {
                builder.addStatement(CodeBlockItemSyntax { builder in
                    builder.useItem(Syntax(SequenceExprSyntax { builder in
                        builder.addElement(ExprSyntax(IdentifierExprSyntax { builder in
                            builder.useIdentifier(SyntaxFactory.makeIdentifier(field.name, leadingTrivia: .spaces(indent + 4), trailingTrivia: .spaces(1)))
                        }))
                        builder.addElement(ExprSyntax(AssignmentExprSyntax { builder in
                            builder.useAssignToken(SyntaxFactory.makeEqualToken(trailingTrivia: .spaces(1)))
                        }))
                        builder.addElement(ExprSyntax(FunctionCallExprSyntax { builder in
                            builder.useCalledExpression(ExprSyntax(MemberAccessExprSyntax { builder in
                                builder.useBase(ExprSyntax(IdentifierExprSyntax { builder in
                                    builder.useIdentifier(SyntaxFactory.makeIdentifier("data"))
                                }))
                                builder.useDot(SyntaxFactory.makePeriodToken())
                                builder.useName(SyntaxFactory.makeIdentifier(field.isFragment ? "getFragment" : "get"))
                            }))
                            builder.useLeftParen(SyntaxFactory.makeLeftParenToken())

                            if !field.isFragment {
                                builder.addArgument(TupleExprElementSyntax { builder in
                                    builder.useExpression(ExprSyntax(MemberAccessExprSyntax { builder in
                                        builder.useBase(ExprSyntax(TypeExprSyntax { builder in
                                            builder.useType(field.type)
                                        }))
                                        builder.useDot(SyntaxFactory.makePeriodToken())
                                        builder.useName(SyntaxFactory.makeIdentifier("self"))
                                    }))
                                    builder.useTrailingComma(SyntaxFactory.makeCommaToken(trailingTrivia: .spaces(1)))
                                })
                            }

                            builder.addArgument(TupleExprElementSyntax { builder in
                                if field.isFragment {
                                    builder.useLabel(SyntaxFactory.makeIdentifier("fragment"))
                                    builder.useColon(SyntaxFactory.makeColonToken(trailingTrivia: .spaces(1)))
                                    builder.useExpression(stringLiteral(field.name.replacingOccurrences(of: "fragment_", with: "")))
                                } else {
                                    builder.useExpression(stringLiteral(field.name))
                                }
                            })

                            builder.useRightParen(SyntaxFactory.makeRightParenToken(trailingTrivia: .newlines(1)))
                        }))
                    }))
                })
            }

            builder.useRightBrace(SyntaxFactory.makeRightBraceToken(leadingTrivia: .spaces(indent), trailingTrivia: .newlines(1)))
        })
    })
}
