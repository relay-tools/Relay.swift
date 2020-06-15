public protocol Storable {
    var name: String { get }
    var storageKey: String? { get }
    var args: [Argument]? { get }
}

extension Storable {
    func storageKey(from variables: VariableData) -> String {
        if let storageKey = storageKey {
            return storageKey
        }

        if let args = args, !args.isEmpty {
            return formatStorageKey(name: name,
                                    variables: getArgumentValues(args, variables))
        } else {
            return name
        }
    }
}

func getArgumentValues(_ args: [Argument], _ variables: VariableData) -> VariableData {
    return Dictionary(uniqueKeysWithValues: args.map {
        ($0.name, $0.value(from: variables))
    }).variableData
}

func formatStorageKey(name: String, variables: VariableDataConvertible?) -> String {
    guard let variables = variables else {
        return name
    }

    let variableData = variables.variableData
    if variableData.isEmpty {
        return name
    }

    return "\(name)(\(variableData.innerDescription))"
}

func getRelayHandleKey(
    handleName: String,
    key: String? = nil,
    fieldName: String? = nil
) -> String {
    if let key = key, !key.isEmpty {
        return "__\(key)_\(handleName)"
    }

    guard let fieldName = fieldName else {
        preconditionFailure("Expected handle to have either a key or a field name")
    }
    return "__\(fieldName)_\(handleName)"
}
