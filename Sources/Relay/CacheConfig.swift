import Foundation

public struct CacheConfig {
    public var force: Bool = false
    public var poll: TimeInterval?
    public var metadata: Any?
    public var transactionID: String?

    public init(
        force: Bool = false,
        poll: TimeInterval? = nil,
        metadata: Any? = nil,
        transactionID: String? = nil
    ) {
        self.force = force
        self.poll = poll
        self.metadata = metadata
        self.transactionID = transactionID
    }
}
