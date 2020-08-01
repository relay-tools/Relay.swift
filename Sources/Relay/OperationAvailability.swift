import Foundation

public enum OperationAvailability: Hashable, CustomStringConvertible {
    case available(Date?)
    case stale
    case missing

    public var description: String {
        switch self {
        case .available: return "available"
        case .stale: return "stale"
        case .missing: return "missing"
        }
    }
}
