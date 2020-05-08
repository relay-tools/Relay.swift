import SwiftSyntax

struct SchemaType {
    var name: String = ""
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
        for (name, _) in byName {
            byName[name]?.name = name
        }
    }

    func syntax(plural: Bool = false, nullable: Bool = false, nullableItems: Bool = false) -> TypeSyntax {
        let typeName: String
        switch name {
        case "ID":
            typeName = "String"
        case "Float":
            typeName = "Double"
        case "Boolean":
            typeName = "Bool"
        default:
            typeName = name
        }

        var typeIdentifier = SyntaxFactory.makeTypeIdentifier(typeName)

        if plural {
            if nullableItems {
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

        if nullable {
            typeIdentifier = TypeSyntax(SyntaxFactory.makeOptionalType(
                wrappedType: typeIdentifier,
                questionMark: SyntaxFactory.makePostfixQuestionMarkToken()
            ))
        }

        return typeIdentifier
    }
}

struct SchemaField {
    var type: String
    var rawType: String
    var isNonNull: Bool
    var isPlural: Bool
    var isNonNullItems: Bool

    var asTypeSyntax: TypeSyntax {
        SchemaType.byName[rawType]!
            .syntax(plural: isPlural, nullable: !isNonNull, nullableItems: !isNonNullItems)
    }
}


