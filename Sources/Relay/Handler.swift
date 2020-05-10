public protocol Handler {
    func update(store: inout RecordSourceProxy, fieldPayload: HandleFieldPayload)
}

public protocol HandlerProvider {
    func handler(for handle: String) -> Handler?
}

public class DefaultHandlerProvider: HandlerProvider {
    public init() {}

    public func handler(for handle: String) -> Handler? {
        switch handle {
        case "connection":
            return ConnectionHandler.default
        default:
            return nil
        }
    }
}
