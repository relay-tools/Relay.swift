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
        case "deleteRecord":
            return DeleteRecordHandler.default
        case "deleteEdge":
            return DeleteEdgeHandler.default
        case "appendEdge":
            return AppendEdgeHandler.default
        case "prependEdge":
            return PrependEdgeHandler.default
        case "appendNode":
            return AppendNodeHandler.default
        case "prependNode":
            return PrependNodeHandler.default
        default:
            return nil
        }
    }
}
