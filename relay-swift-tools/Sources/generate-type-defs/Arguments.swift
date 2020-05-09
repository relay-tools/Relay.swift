import Foundation
import SwiftSyntax

func makeArgumentsExpr(args: [[String: Any]], indent: Int) -> ExprSyntax {
    ExprSyntax(ArrayExprSyntax { builder in
        builder.useLeftSquare(SyntaxFactory.makeLeftSquareBracketToken(trailingTrivia: .newlines(1)))

        for arg in args {
            builder.addElement(ArrayElementSyntax { builder in
                builder.useExpression(makeArgumentExpr(arg: arg).withLeadingTrivia(.spaces(indent + 4)))
                builder.useTrailingComma(SyntaxFactory.makeCommaToken(trailingTrivia: .newlines(1)))
            })
        }

        builder.useRightSquare(SyntaxFactory.makeRightSquareBracketToken(leadingTrivia: .spaces(indent)))
    })
}

func makeArgumentExpr(arg: [String: Any]) -> ExprSyntax {
    ExprSyntax(FunctionCallExprSyntax { builder in
        let kind = arg["kind"] as! String

        builder.useCalledExpression(ExprSyntax(IdentifierExprSyntax { builder in
            builder.useIdentifier(SyntaxFactory.makeIdentifier("\(kind)Argument"))
        }))
        builder.useLeftParen(SyntaxFactory.makeLeftParenToken())

        var args = [(String, ExprSyntax)]()

        args.append(("name", stringLiteral(arg["name"] as! String)))

        if let type = arg["type"] as? String {
            args.append(("type", stringLiteral(type)))
        }

        if let variableName = arg["variableName"] as? String {
            args.append(("variableName", stringLiteral(variableName)))
        }

        if let value = arg["value"] {
            args.append(("value", argumentValueLiteral(value)))
        }

        for (i, (name, expr)) in args.enumerated() {
            builder.addArgument(TupleExprElementSyntax { builder in
                builder.useLabel(SyntaxFactory.makeIdentifier(name))
                builder.useColon(SyntaxFactory.makeColonToken(trailingTrivia: .spaces(1)))
                builder.useExpression(expr)
                if i < args.count - 1 {
                    builder.useTrailingComma(SyntaxFactory.makeCommaToken(trailingTrivia: .spaces(1)))
                }
            })
        }

        builder.useRightParen(SyntaxFactory.makeRightParenToken())
    })
}

private func argumentValueLiteral(_ value: Any) -> ExprSyntax {
    if let value = value as? Int {
        return ExprSyntax(IntegerLiteralExprSyntax { builder in
            builder.useDigits(SyntaxFactory.makeIntegerLiteral("\(value)"))
        })
    } else if let value = value as? String {
        return stringLiteral(value)
    } else if let value = value as? Bool {
        return boolLiteral(value)
    } else if value is NSNull {
        return ExprSyntax(NilLiteralExprSyntax { builder in
            builder.useNilKeyword(SyntaxFactory.makeNilKeyword())
        })
    } else {
        preconditionFailure("Not sure how to write a literal for value of type \(type(of: value))")
    }
}
