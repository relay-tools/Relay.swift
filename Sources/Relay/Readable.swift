public protocol ReadableScalar {
    init(from value: SelectorData.Value)
}

extension Int: ReadableScalar {
    public init(from value: SelectorData.Value) {
        guard case .int(let v) = value else {
            preconditionFailure("Tried to decode an Int from a non-integer value: \(value)")
        }

        self = v
    }
}

extension Double: ReadableScalar {
    public init(from value: SelectorData.Value) {
        if case .float(let v) = value {
            self = v
        } else if case .int(let v) = value {
            self = .init(v)
        } else {
            preconditionFailure("Tried to decode a Double from a non-float value: \(value)")
        }
    }
}

extension String: ReadableScalar {
    public init(from value: SelectorData.Value) {
        guard case .string(let v) = value else {
            preconditionFailure("Tried to decode a String from a non-string value: \(value)")
        }

        self = v
    }
}

extension Bool: ReadableScalar {
    public init(from value: SelectorData.Value) {
        if case .int(let v) = value {
            self = v != 0
            return
        }

        guard case .bool(let v) = value else {
            preconditionFailure("Tried to decode a Bool from a non-boolean value: \(value)")
        }

        self = v
    }
}

public extension RawRepresentable where RawValue == String {
    init(from value: SelectorData.Value) {
        guard case .string(let v) = value else {
            preconditionFailure("Tried to decode an String from a non-string value: \(value)")
        }

        self.init(rawValue: v)!
    }
}
