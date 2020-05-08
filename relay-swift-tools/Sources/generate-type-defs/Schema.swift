import SwiftSyntax

struct SchemaType {
    var fields: [String: SchemaField] = [:]

    static var byName: [String: SchemaType] = [:]

    static func loadAll(_ types: [String: Any]) {
        byName = (types as! [String: [String: Any]]).mapValues { typeData in
            var type = SchemaType()

            if let fields = typeData["fields"] as? [String: [String: Any]] {
                type.fields = fields.mapValues { fieldData in
                    SchemaField(
                        type: fieldData["type"] as! String,
                        rawType: fieldData["rawType"] as! String,
                        isNonNull: fieldData["isNonNull"] as! Bool,
                        isPlural: fieldData["isPlural"] as! Bool,
                        isNonNullItems: fieldData["isNonNullItems"] as! Bool
                    )
                }
            }

            return type
        }
    }
}

struct SchemaField {
    var type: String
    var rawType: String
    var isNonNull: Bool
    var isPlural: Bool
    var isNonNullItems: Bool

    var asTypeSyntax: TypeSyntax {
        var typeIdentifier = SyntaxFactory.makeTypeIdentifier(rawType)

        if isPlural {
            if !isNonNullItems {
                typeIdentifier = TypeSyntax(SyntaxFactory.makeOptionalType(
                    wrappedType: typeIdentifier,
                    questionMark: SyntaxFactory.makePostfixQuestionMarkToken()
                ))
            }

            typeIdentifier = TypeSyntax(SyntaxFactory.makeArrayType(
                leftSquareBracket: SyntaxFactory.makeLeftSquareBracketToken(),
                elementType: typeIdentifier,
                rightSquareBracket: SyntaxFactory.makeRightSquareBracketToken()
            ))
        }

        if !isNonNull {
            typeIdentifier = TypeSyntax(SyntaxFactory.makeOptionalType(
                wrappedType: typeIdentifier,
                questionMark: SyntaxFactory.makePostfixQuestionMarkToken()
            ))
        }

        return typeIdentifier
    }
}


