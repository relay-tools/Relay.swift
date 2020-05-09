import SwiftSyntax

func makeConcreteRequestExpr(input: [String: Any]) -> ExprSyntax {
    ExprSyntax(FunctionCallExprSyntax { builder in
        builder.useCalledExpression(ExprSyntax(IdentifierExprSyntax { builder in
            builder.useIdentifier(SyntaxFactory.makeIdentifier("ConcreteRequest"))
        }))
        builder.useLeftParen(SyntaxFactory.makeLeftParenToken(trailingTrivia: .newlines(1)))

        var args = [(String, ExprSyntax)]()

        if let fragment = input["fragment"] as? [String: Any] {
            args.append(("fragment", makeReaderFragmentExpr(node: fragment, indent: 12)))
        }

        if let operation = input["operation"] as? [String: Any] {
            args.append(("operation", makeNormalizationNodeExpr(node: operation, indent: 12)))
        }

        if let params = input["params"] as? [String: Any] {
            args.append(("params", makeRequestParamsExpr(node: params, indent: 12)))
        }

        for (i, (name, expr)) in args.enumerated() {
            builder.addArgument(TupleExprElementSyntax { builder in
                builder.useLabel(SyntaxFactory.makeIdentifier(name, leadingTrivia: .spaces(12)))
                builder.useColon(SyntaxFactory.makeColonToken(trailingTrivia: .spaces(1)))
                builder.useExpression(expr)
                if i < args.count - 1 {
                    builder.useTrailingComma(SyntaxFactory.makeCommaToken())
                }
            }.withTrailingTrivia(.newlines(1)))
        }

        builder.useRightParen(SyntaxFactory.makeRightParenToken(leadingTrivia: .spaces(8)))
    })
}

private func makeNormalizationNodeExpr(node: [String: Any], indent: Int) -> ExprSyntax {
    ExprSyntax(FunctionCallExprSyntax { builder in
        builder.useCalledExpression(ExprSyntax(IdentifierExprSyntax { builder in
            builder.useIdentifier(SyntaxFactory.makeIdentifier("NormalizationOperation"))
        }))
        builder.useLeftParen(SyntaxFactory.makeLeftParenToken(trailingTrivia: .newlines(1)))

        var args = [(String, ExprSyntax)]()

        if let name = node["name"] as? String {
            args.append(("name", stringLiteral(name)))
        }

        if let selections = node["selections"] as? [[String: Any]] {
            args.append(("selections", makeNormalizationSelectionsExpr(selections: selections, indent: indent + 4)))
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

private func makeNormalizationSelectionsExpr(selections: [[String: Any]], indent: Int) -> ExprSyntax {
    ExprSyntax(ArrayExprSyntax { builder in
        builder.useLeftSquare(SyntaxFactory.makeLeftSquareBracketToken(trailingTrivia: .newlines(1)))

        for selection in selections {
            builder.addElement(ArrayElementSyntax { builder in
                builder.useExpression(makeNormalizationSelectionExpr(selection: selection, indent: indent + 4))
                builder.useTrailingComma(SyntaxFactory.makeCommaToken(trailingTrivia: .newlines(1)))
            })
        }

        builder.useRightSquare(SyntaxFactory.makeRightSquareBracketToken(leadingTrivia: .spaces(indent)))
    })
}

private func makeNormalizationSelectionExpr(selection: [String: Any], indent: Int) -> ExprSyntax {
    let kind = selection["kind"] as! String

    return ExprSyntax(FunctionCallExprSyntax { builder in
        builder.useCalledExpression(ExprSyntax(MemberAccessExprSyntax { builder in
            builder.useDot(SyntaxFactory.makePeriodToken(leadingTrivia: .spaces(indent)))
            if kind == "LinkedField" || kind == "ScalarField" {
                builder.useName(SyntaxFactory.makeIdentifier("field"))
            } else if kind == "LinkedHandle" || kind == "ScalarHandle" {
                builder.useName(SyntaxFactory.makeIdentifier("handle"))
            }
        }))
        builder.useLeftParen(SyntaxFactory.makeLeftParenToken())

        builder.addArgument(TupleExprElementSyntax { builder in
            builder.useExpression(ExprSyntax(FunctionCallExprSyntax { builder in
                builder.useCalledExpression(ExprSyntax(IdentifierExprSyntax { builder in
                    if kind.hasSuffix("Handle") {
                        builder.useIdentifier(SyntaxFactory.makeIdentifier("NormalizationHandle"))
                    } else {
                        builder.useIdentifier(SyntaxFactory.makeIdentifier("Normalization\(kind)"))
                    }
                }))
                builder.useLeftParen(SyntaxFactory.makeLeftParenToken(trailingTrivia: .newlines(1)))

                var args = [(String, ExprSyntax)]()
                func addArgument(_ name: String, _ expression: ExprSyntax) {
                    args.append((name, expression))
                }

                if kind.hasSuffix("Handle") {
                    addArgument("kind", ExprSyntax(MemberAccessExprSyntax { builder in
                        builder.useDot(SyntaxFactory.makePeriodToken())
                        builder.useName(SyntaxFactory.makeIdentifier(kind == "LinkedHandle" ? "linked" : "scalar"))
                    }))
                }

                addArgument("name", stringLiteral(selection["name"] as! String))

                if let alias = selection["alias"] as? String {
                    addArgument("alias", stringLiteral(alias))
                }

                if let args = selection["args"] as? [[String: Any]] {
                    addArgument("args", makeArgumentsExpr(args: args, indent: indent + 4))
                }

                if let handle = selection["handle"] as? String {
                    addArgument("handle", stringLiteral(handle))
                }

                if let key = selection["key"] as? String {
                    addArgument("key", stringLiteral(key))
                }

                // TODO filters

                if let storageKey = selection["storageKey"] as? String {
                    addArgument("storageKey", stringLiteral(storageKey))
                }

                if let concreteType = selection["concreteType"] as? String {
                    addArgument("concreteType", stringLiteral(concreteType))
                }

                if let plural = selection["plural"] as? Bool {
                    addArgument("plural", boolLiteral(plural))
                }

                if let selections = selection["selections"] as? [[String: Any]] {
                    addArgument("selections", makeNormalizationSelectionsExpr(selections: selections, indent: indent + 4))
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


private func makeRequestParamsExpr(node: [String: Any], indent: Int) -> ExprSyntax {
    ExprSyntax(FunctionCallExprSyntax { builder in
        builder.useCalledExpression(ExprSyntax(IdentifierExprSyntax { builder in
            builder.useIdentifier(SyntaxFactory.makeIdentifier("RequestParameters"))
        }))
        builder.useLeftParen(SyntaxFactory.makeLeftParenToken(trailingTrivia: .newlines(1)))

        var args = [(String, ExprSyntax)]()

        if let name = node["name"] as? String {
            args.append(("name", stringLiteral(name)))
        }

        if let operationKind = node["operationKind"] as? String {
            args.append(("operationKind", ExprSyntax(MemberAccessExprSyntax { builder in
                builder.useDot(SyntaxFactory.makePeriodToken())
                builder.useName(SyntaxFactory.makeIdentifier(operationKind.lowercased()))
            })))
        }

        if let text = node["text"] as? String {
            args.append(("text", multiLineStringLiteral(text)))
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
