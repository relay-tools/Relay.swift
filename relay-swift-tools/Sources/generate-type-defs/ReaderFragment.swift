import SwiftSyntax

func makeReaderFragmentExpr(node: [String: Any]) -> ExprSyntax {
    ExprSyntax(FunctionCallExprSyntax { builder in
        builder.useCalledExpression(ExprSyntax(IdentifierExprSyntax { builder in
            builder.useIdentifier(SyntaxFactory.makeIdentifier("ReaderFragment"))
        }))
        builder.useLeftParen(SyntaxFactory.makeLeftParenToken())
    })
}
