import SwiftSyntax

func makePaginationFragmentExtensionDecl(node: [String: Any]) -> DeclSyntax {
    let name = node["name"] as! String
    let metadata = node["metadata"] as! [String: Any]
    let refetchMetadata = metadata["refetch"] as! [String: Any]

    let operation = refetchMetadata["operation"] as! String
    let operationName = operation
        .replacingOccurrences(of: "@@MODULE_START@@", with: "")
        .replacingOccurrences(of: ".graphql@@MODULE_END@@", with: "")

    return DeclSyntax(ExtensionDeclSyntax { builder in
        builder.useExtensionKeyword(SyntaxFactory.makeExtensionKeyword(trailingTrivia: .spaces(1)))
        builder.useExtendedType(SyntaxFactory.makeTypeIdentifier(name))
        builder.useInheritanceClause(TypeInheritanceClauseSyntax { builder in
            builder.useColon(SyntaxFactory.makeColonToken(trailingTrivia: .spaces(1)))
            builder.addInheritedType(InheritedTypeSyntax { builder in
                builder.useTypeName(SyntaxFactory.makeTypeIdentifier("PaginationFragment", trailingTrivia: .spaces(1)))
            })
        })
        builder.useMembers(MemberDeclBlockSyntax { builder in
            builder.useLeftBrace(SyntaxFactory.makeLeftBraceToken(trailingTrivia: .newlines(1)))

            builder.addMember(MemberDeclListItemSyntax { builder in
                builder.useDecl(DeclSyntax(TypealiasDeclSyntax { builder in
                    builder.useTypealiasKeyword(SyntaxFactory.makeTypealiasKeyword(leadingTrivia: .spaces(4), trailingTrivia: .spaces(1)))
                    builder.useIdentifier(SyntaxFactory.makeIdentifier("Operation"))
                    builder.useInitializer(TypeInitializerClauseSyntax { builder in
                        builder.useEqual(SyntaxFactory.makeEqualToken(leadingTrivia: .spaces(1), trailingTrivia: .spaces(1)))
                        builder.useValue(SyntaxFactory.makeTypeIdentifier(operationName, trailingTrivia: .newlines(2)))
                    })
                }))
            })

            builder.addMember(MemberDeclListItemSyntax { builder in
                builder.useDecl(DeclSyntax(VariableDeclSyntax { builder in
                    builder.useLetOrVarKeyword(SyntaxFactory.makeVarKeyword(leadingTrivia: .spaces(4), trailingTrivia: .spaces(1)))
                    builder.addBinding(PatternBindingSyntax { builder in
                        builder.usePattern(PatternSyntax(IdentifierPatternSyntax { builder in
                            builder.useIdentifier(SyntaxFactory.makeIdentifier("metadata"))
                        }))
                        builder.useTypeAnnotation(TypeAnnotationSyntax { builder in
                            builder.useColon(SyntaxFactory.makeColonToken(trailingTrivia: .spaces(1)))
                            builder.useType(SyntaxFactory.makeTypeIdentifier("Metadata", trailingTrivia: .spaces(1)))
                        })
                        builder.useAccessor(Syntax(CodeBlockSyntax { builder in
                            builder.useLeftBrace(SyntaxFactory.makeLeftBraceToken(trailingTrivia: .newlines(1)))

                            builder.addStatement(CodeBlockItemSyntax { builder in
                                builder.useItem(Syntax(ReturnStmtSyntax { builder in
                                    builder.useExpression(ExprSyntax(FunctionCallExprSyntax { builder in
                                        builder.useCalledExpression(ExprSyntax(IdentifierExprSyntax { builder in
                                            builder.useIdentifier(SyntaxFactory.makeIdentifier("RefetchMetadata", leadingTrivia: .spaces(8)))
                                        }))
                                        builder.useLeftParen(SyntaxFactory.makeLeftParenToken())

                                        builder.addArgument(TupleExprElementSyntax { builder in
                                            builder.useLabel(SyntaxFactory.makeIdentifier("path", leadingTrivia: .newlines(1) + .spaces(12)))
                                            builder.useColon(SyntaxFactory.makeColonToken(trailingTrivia: .spaces(1)))
                                            builder.useExpression(makeKeyPathArrayLiteral(path: refetchMetadata["fragmentPathInResult"] as! [Any]))
                                            builder.useTrailingComma(SyntaxFactory.makeCommaToken(trailingTrivia: .newlines(1)))
                                        })

                                        builder.addArgument(TupleExprElementSyntax { builder in
                                            builder.useLabel(SyntaxFactory.makeIdentifier("operation", leadingTrivia: .spaces(12)))
                                            builder.useColon(SyntaxFactory.makeColonToken(trailingTrivia: .spaces(1)))
                                            builder.useExpression(ExprSyntax(FunctionCallExprSyntax { builder in
                                                builder.useCalledExpression(ExprSyntax(MemberAccessExprSyntax { builder in
                                                    builder.useDot(SyntaxFactory.makePeriodToken())
                                                    builder.useName(SyntaxFactory.makeIdentifier("init"))
                                                }))
                                                builder.useLeftParen(SyntaxFactory.makeLeftParenToken())
                                                builder.useRightParen(SyntaxFactory.makeRightParenToken())
                                            }))
                                            builder.useTrailingComma(SyntaxFactory.makeCommaToken(trailingTrivia: .newlines(1)))
                                        })

                                        builder.addArgument(TupleExprElementSyntax { builder in
                                            let connectionMetadata = refetchMetadata["connection"] as! [String: Any]

                                            builder.useLabel(SyntaxFactory.makeIdentifier("connection", leadingTrivia: .spaces(12)))
                                            builder.useColon(SyntaxFactory.makeColonToken(trailingTrivia: .spaces(1)))
                                            builder.useExpression(ExprSyntax(FunctionCallExprSyntax { builder in
                                                builder.useCalledExpression(ExprSyntax(IdentifierExprSyntax { builder in
                                                    builder.useIdentifier(SyntaxFactory.makeIdentifier("ConnectionMetadata"))
                                                }))
                                                builder.useLeftParen(SyntaxFactory.makeLeftParenToken(trailingTrivia: .newlines(1)))

                                                var args: [(String, ExprSyntax)] = []

                                                args.append(("path", makeKeyPathArrayLiteral(path: connectionMetadata["path"] as! [Any])))

                                                if let forward = connectionMetadata["forward"] as? [String: Any] {
                                                    args.append(("forward", makeConnectionVariableConfigExpr(config: forward)))
                                                }
                                                if let backward = connectionMetadata["backward"] as? [String: Any] {
                                                    args.append(("backward", makeConnectionVariableConfigExpr(config: backward)))
                                                }

                                                for (i, (name, expr)) in args.enumerated() {
                                                    builder.addArgument(TupleExprElementSyntax { builder in
                                                        builder.useLabel(SyntaxFactory.makeIdentifier(name, leadingTrivia: .spaces(16)))
                                                        builder.useColon(SyntaxFactory.makeColonToken(trailingTrivia: .spaces(1)))
                                                        builder.useExpression(expr)
                                                        if i < args.count - 1 {
                                                            builder.useTrailingComma(SyntaxFactory.makeCommaToken(trailingTrivia: .newlines(1)))
                                                        }
                                                    })
                                                }

                                                builder.useRightParen(SyntaxFactory.makeRightParenToken())
                                            }))
                                        })

                                        builder.useRightParen(SyntaxFactory.makeRightParenToken())
                                    }))
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
}

private func makeKeyPathArrayLiteral(path: [Any]) -> ExprSyntax {
    ExprSyntax(ArrayExprSyntax { builder in
        builder.useLeftSquare(SyntaxFactory.makeLeftSquareBracketToken())

        for (i, pathElement) in path.enumerated() {
            builder.addElement(ArrayElementSyntax { builder in
                if let element = pathElement as? String {
                    builder.useExpression(stringLiteral(element))
                } else if let element = pathElement as? Int {
                    builder.useExpression(ExprSyntax(IntegerLiteralExprSyntax { builder in
                        builder.useDigits(SyntaxFactory.makeIntegerLiteral("\(element)"))
                    }))
                }

                if i < path.count - 1 {
                    builder.useTrailingComma(SyntaxFactory.makeCommaToken(trailingTrivia: .spaces(1)))
                }
            })
        }

        builder.useRightSquare(SyntaxFactory.makeRightSquareBracketToken())
    })
}

private func makeConnectionVariableConfigExpr(config: [String: Any]) -> ExprSyntax {
    ExprSyntax(FunctionCallExprSyntax { builder in
        builder.useCalledExpression(ExprSyntax(IdentifierExprSyntax { builder in
            builder.useIdentifier(SyntaxFactory.makeIdentifier("ConnectionVariableConfig"))
        }))
        builder.useLeftParen(SyntaxFactory.makeLeftParenToken())

        builder.addArgument(TupleExprElementSyntax { builder in
            builder.useLabel(SyntaxFactory.makeIdentifier("count"))
            builder.useColon(SyntaxFactory.makeColonToken(trailingTrivia: .spaces(1)))
            builder.useExpression(stringLiteral(config["count"] as! String))
            builder.useTrailingComma(SyntaxFactory.makeCommaToken(trailingTrivia: .spaces(1)))
        })

        builder.addArgument(TupleExprElementSyntax { builder in
            builder.useLabel(SyntaxFactory.makeIdentifier("cursor"))
            builder.useColon(SyntaxFactory.makeColonToken(trailingTrivia: .spaces(1)))
            builder.useExpression(stringLiteral(config["cursor"] as! String))
        })

        builder.useRightParen(SyntaxFactory.makeRightParenToken())
    })
}