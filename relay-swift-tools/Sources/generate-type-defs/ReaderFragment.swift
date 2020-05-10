import SwiftSyntax

func makeReaderFragmentExpr(node: [String: Any], indent: Int) -> ExprSyntax {
    ExprSyntax(FunctionCallExprSyntax { builder in
        builder.useCalledExpression(ExprSyntax(IdentifierExprSyntax { builder in
            builder.useIdentifier(SyntaxFactory.makeIdentifier("ReaderFragment"))
        }))
        builder.useLeftParen(SyntaxFactory.makeLeftParenToken(trailingTrivia: .newlines(1)))

        var args = [(String, ExprSyntax)]()

        if let name = node["name"] as? String {
            args.append(("name", stringLiteral(name)))
        }

        if let selections = node["selections"] as? [[String: Any]] {
            args.append(("selections", makeReaderSelectionsExpr(selections: selections, indent: indent + 4)))
        }

        for (i, (name, expr)) in args.enumerated() {
            builder.addArgument(TupleExprElementSyntax { builder in
                builder.useLabel(SyntaxFactory.makeIdentifier(name, leadingTrivia: .spaces(indent + 4)))
                builder.useColon(SyntaxFactory.makeColonToken(trailingTrivia: .spaces(1)))
                builder.useExpression(expr)
                if i < args.count - 1 {
                    builder.useTrailingComma(SyntaxFactory.makeCommaToken())
                }
            }.withTrailingTrivia(.newlines(1)))
        }

        builder.useRightParen(SyntaxFactory.makeRightParenToken(leadingTrivia: .spaces(indent)))
    })
}

private func makeReaderSelectionsExpr(selections: [[String: Any]], indent: Int) -> ExprSyntax {
    ExprSyntax(ArrayExprSyntax { builder in
        builder.useLeftSquare(SyntaxFactory.makeLeftSquareBracketToken(trailingTrivia: .newlines(1)))

        for selection in selections {
            builder.addElement(ArrayElementSyntax { builder in
                builder.useExpression(makeReaderSelectionExpr(selection: selection, indent: indent + 4))
                builder.useTrailingComma(SyntaxFactory.makeCommaToken(trailingTrivia: .newlines(1)))
            })
        }

        builder.useRightSquare(SyntaxFactory.makeRightSquareBracketToken(leadingTrivia: .spaces(indent)))
    })
}

private func makeReaderSelectionExpr(selection: [String: Any], indent: Int) -> ExprSyntax {
    let kind = selection["kind"] as! String

    return ExprSyntax(FunctionCallExprSyntax { builder in
        builder.useCalledExpression(ExprSyntax(MemberAccessExprSyntax { builder in
            builder.useDot(SyntaxFactory.makePeriodToken(leadingTrivia: .spaces(indent)))
            if kind == "LinkedField" || kind == "ScalarField" {
                builder.useName(SyntaxFactory.makeIdentifier("field"))
            } else if kind == "FragmentSpread" {
                builder.useName(SyntaxFactory.makeIdentifier("fragmentSpread"))
            }
        }))
        builder.useLeftParen(SyntaxFactory.makeLeftParenToken())

        builder.addArgument(TupleExprElementSyntax { builder in
            builder.useExpression(ExprSyntax(FunctionCallExprSyntax { builder in
                builder.useCalledExpression(ExprSyntax(IdentifierExprSyntax { builder in
                    builder.useIdentifier(SyntaxFactory.makeIdentifier("Reader\(kind)"))
                }))
                builder.useLeftParen(SyntaxFactory.makeLeftParenToken(trailingTrivia: .newlines(1)))

                var args = [(String, ExprSyntax)]()
                func addArgument(_ name: String, _ expression: ExprSyntax) {
                    args.append((name, expression))
                }

                addArgument("name", stringLiteral(selection["name"] as! String))

                if let alias = selection["alias"] as? String {
                    addArgument("alias", stringLiteral(alias))
                }

                if let args = selection["args"] as? [[String: Any]] {
                    addArgument("args", makeArgumentsExpr(args: args, indent: indent + 4))
                }

                if let concreteType = selection["concreteType"] as? String {
                    addArgument("concreteType", stringLiteral(concreteType))
                }

                if let plural = selection["plural"] as? Bool {
                    addArgument("plural", boolLiteral(plural))
                }

                if let selections = selection["selections"] as? [[String: Any]] {
                    addArgument("selections", makeReaderSelectionsExpr(selections: selections, indent: indent + 4))
                }

                for (i, (name, expr)) in args.enumerated() {
                    builder.addArgument(TupleExprElementSyntax { builder in
                        builder.useLabel(SyntaxFactory.makeIdentifier(name, leadingTrivia: .spaces(indent + 4)))
                        builder.useColon(SyntaxFactory.makeColonToken(trailingTrivia: .spaces(1)))
                        builder.useExpression(expr)
                        if i < args.count - 1 {
                            builder.useTrailingComma(SyntaxFactory.makeCommaToken())
                        }
                    }.withTrailingTrivia(.newlines(1)))
                }

                builder.useRightParen(SyntaxFactory.makeRightParenToken(leadingTrivia: .spaces(indent)))
            }))
        })

        builder.useRightParen(SyntaxFactory.makeRightParenToken())
    })
}

func makeGetFragmentPointerFuncDecl(name: String) -> DeclSyntax {
    DeclSyntax(FunctionDeclSyntax { builder in
        builder.useFuncKeyword(SyntaxFactory.makeFuncKeyword(leadingTrivia: .spaces(4), trailingTrivia: .spaces(1)))
        builder.useIdentifier(SyntaxFactory.makeIdentifier("getFragmentPointer"))
        builder.useSignature(FunctionSignatureSyntax { builder in
            builder.useInput(ParameterClauseSyntax { builder in
                builder.useLeftParen(SyntaxFactory.makeLeftParenToken())
                builder.addParameter(FunctionParameterSyntax { builder in
                    builder.useFirstName(SyntaxFactory.makeIdentifier("_", trailingTrivia: .spaces(1)))
                    builder.useSecondName(SyntaxFactory.makeIdentifier("key"))
                    builder.useColon(SyntaxFactory.makeColonToken(trailingTrivia: .spaces(1)))
                    builder.useType(SyntaxFactory.makeTypeIdentifier("\(name)_Key"))
                })
                builder.useRightParen(SyntaxFactory.makeRightParenToken(trailingTrivia: .spaces(1)))
            })
            builder.useOutput(ReturnClauseSyntax { builder in
                builder.useArrow(SyntaxFactory.makeArrowToken(trailingTrivia: .spaces(1)))
                builder.useReturnType(SyntaxFactory.makeTypeIdentifier("FragmentPointer"))
            })
        })
        builder.useBody(CodeBlockSyntax { builder in
            builder.useLeftBrace(SyntaxFactory.makeLeftBraceToken(leadingTrivia: .spaces(1), trailingTrivia: .newlines(1)))

            builder.addStatement(CodeBlockItemSyntax { builder in
                builder.useItem(Syntax(ReturnStmtSyntax { builder in
                    builder.useReturnKeyword(SyntaxFactory.makeReturnKeyword(leadingTrivia: .spaces(8), trailingTrivia: .spaces(1)))
                    builder.useExpression(ExprSyntax(MemberAccessExprSyntax { builder in
                        builder.useBase(ExprSyntax(IdentifierExprSyntax { builder in
                            builder.useIdentifier(SyntaxFactory.makeIdentifier("key"))
                        }))
                        builder.useDot(SyntaxFactory.makePeriodToken())
                        builder.useName(SyntaxFactory.makeIdentifier("fragment_\(name)", trailingTrivia: .newlines(1)))
                    }))
                }))
            })

            builder.useRightBrace(SyntaxFactory.makeRightBraceToken(leadingTrivia: .spaces(4)))
        })
    })
}

func makeFragmentProtocolDecl(name: String) -> DeclSyntax {
    DeclSyntax(ProtocolDeclSyntax { builder in
        builder.useProtocolKeyword(SyntaxFactory.makeProtocolKeyword(trailingTrivia: .spaces(1)))
        builder.useIdentifier(SyntaxFactory.makeIdentifier("\(name)_Key", trailingTrivia: .spaces(1)))
        builder.useMembers(MemberDeclBlockSyntax { builder in
            builder.useLeftBrace(SyntaxFactory.makeLeftBraceToken(trailingTrivia: .newlines(1)))

            builder.addMember(MemberDeclListItemSyntax { builder in
                builder.useDecl(DeclSyntax(VariableDeclSyntax { builder in
                    builder.useLetOrVarKeyword(SyntaxFactory.makeVarKeyword(leadingTrivia: .spaces(4), trailingTrivia: .spaces(1)))
                    builder.addBinding(PatternBindingSyntax { builder in
                        builder.usePattern(PatternSyntax(IdentifierPatternSyntax { builder in
                            builder.useIdentifier(SyntaxFactory.makeIdentifier("fragment_\(name)"))
                        }))
                        builder.useTypeAnnotation(TypeAnnotationSyntax { builder in
                            builder.useColon(SyntaxFactory.makeColonToken(trailingTrivia: .spaces(1)))
                            builder.useType(SyntaxFactory.makeTypeIdentifier("FragmentPointer"))
                        })
                        builder.useAccessor(Syntax(AccessorBlockSyntax { builder in
                            builder.useLeftBrace(SyntaxFactory.makeLeftBraceToken(leadingTrivia: .spaces(1)))
                            builder.addAccessor(AccessorDeclSyntax { builder in
                                builder.useAccessorKind(SyntaxFactory.makeContextualKeyword("get", leadingTrivia: .spaces(1), trailingTrivia: .spaces(1)))
                            })
                            builder.useRightBrace(SyntaxFactory.makeRightBraceToken())
                        }))
                    }.withTrailingTrivia(.newlines(1)))
                }))
            })

            builder.useRightBrace(SyntaxFactory.makeRightBraceToken(trailingTrivia: .newlines(1)))
        })
    })
}
