import Foundation

public enum OperationAvailability: Hashable {
    case available(Date?)
    case stale
    case missing
}
