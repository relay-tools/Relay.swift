import SwiftSyntax
import Foundation

let filePath = ProcessInfo.processInfo.arguments[1]

// TODO read this from stdin
let text = String(data: FileHandle(forReadingAtPath: filePath)!.readDataToEndOfFile(), encoding: .utf8)!

struct GraphQLTag: Encodable {
    var template: String
    var keyName: String?
    var sourceLocationOffset: SourceLocationOffset
}

struct SourceLocationOffset: Encodable {
    var line: Int
    var column: Int
}

let syntax = try SyntaxParser.parse(source: text, filenameForDiagnostics: (filePath as NSString).lastPathComponent)
let converter = SourceLocationConverter(file: filePath, tree: syntax)

class Visitor: SyntaxVisitor {
    var tags: [GraphQLTag] = []

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let ident = node.calledExpression.as(IdentifierExprSyntax.self) else {
            return .visitChildren
        }

        guard ident.identifier.text == "graphql", node.argumentList.count == 1 else {
            return .visitChildren
        }

        guard let stringLiteral = node.argumentList.first?.expression.as(StringLiteralExprSyntax.self) else {
            return .skipChildren
        }

        let template = stringLiteral.segments.compactMap { $0.as(StringSegmentSyntax.self)?.content.text }.joined(separator: "")
        let startPosition = node.startLocation(converter: converter)

        tags.append(GraphQLTag(template: template, keyName: nil, sourceLocationOffset: SourceLocationOffset(line: startPosition.line!, column: startPosition.column!)))

        return .skipChildren
    }
}

let visitor = Visitor()
visitor.walk(syntax)

let data = try JSONEncoder().encode(visitor.tags)
FileHandle.standardOutput.write(data)
