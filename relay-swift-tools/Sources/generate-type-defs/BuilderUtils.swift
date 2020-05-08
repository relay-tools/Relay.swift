import SwiftSyntax

func stringLiteral(_ text: String) -> ExprSyntax {
    ExprSyntax(StringLiteralExprSyntax { builder in
        builder.useOpenQuote(SyntaxFactory.makeStringQuoteToken())
        builder.addSegment(Syntax(SyntaxFactory.makeStringSegment(text)))
        builder.useCloseQuote(SyntaxFactory.makeStringQuoteToken())
    })
}

func multiLineStringLiteral(_ text: String) -> ExprSyntax {
    ExprSyntax(StringLiteralExprSyntax { builder in
        builder.useOpenQuote(SyntaxFactory.makeMultilineStringQuoteToken(trailingTrivia: .newlines(1)))
        builder.addSegment(Syntax(SyntaxFactory.makeStringSegment(text)))
        builder.useCloseQuote(SyntaxFactory.makeMultilineStringQuoteToken())
    })
}

func boolLiteral(_ value: Bool) -> ExprSyntax {
    ExprSyntax(BooleanLiteralExprSyntax { builder in
        if value {
            builder.useBooleanLiteral(SyntaxFactory.makeTrueKeyword())
        } else {
            builder.useBooleanLiteral(SyntaxFactory.makeFalseKeyword())
        }
    })
}
