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
