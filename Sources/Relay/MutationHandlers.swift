import os

private let logger = Logger(subsystem: "io.github.mjm.Relay", category: "mutations")

public class DeleteRecordHandler: Handler {
    public static let `default` = DeleteRecordHandler()

    public init() {}

    public func update(store: inout RecordSourceProxy, fieldPayload payload: HandleFieldPayload) {
        guard let record = store[payload.dataID] else {
            return
        }

        let idOrIds = record[payload.fieldKey]
        if let id = idOrIds as? String {
            store.delete(dataID: DataID(id))
        } else if let ids = idOrIds as? [String] {
            for id in ids {
                store.delete(dataID: DataID(id))
            }
        }
    }
}

public class DeleteEdgeHandler: Handler {
    public static let `default` = DeleteEdgeHandler()

    public init() {}

    public func update(store: inout RecordSourceProxy, fieldPayload payload: HandleFieldPayload) {
        guard let record = store[payload.dataID] else {
            return
        }

        guard case .array(let connections) = payload.handleArgs.connections else {
            preconditionFailure("DeleteEdgeHandler: Expected array of connection IDs to be specified.")
        }

        let idOrIds = record[payload.fieldKey]
        let idList: [String]
        if let id = idOrIds as? String {
            idList = [id]
        } else if let ids = idOrIds as? [String] {
            idList = ids
        } else {
            preconditionFailure("DeleteEdgeHandler: Expected field to be either an ID or an array of IDs.")
        }

        for id in idList {
            for connectionID in connections {
                guard case .string(let connectionID) = connectionID else {
                    preconditionFailure("DeleteEdgeHandler: Expected connection ID to be a string.")
                }
                guard var connection = store[DataID(connectionID)] else {
                    logger.warning("The connection with ID '\(connectionID, privacy: .public)' doesn't exist.")
                    continue
                }

                ConnectionHandler.default.delete(connection: &connection, nodeID: DataID(id))
            }
        }
    }
}

public class AppendEdgeHandler: Handler {
    public static let `default` = AppendEdgeHandler()

    public init() {}

    public func update(store: inout RecordSourceProxy, fieldPayload: HandleFieldPayload) {
        updateEdge(
            store: &store,
            fieldPayload: fieldPayload,
            insertFn: ConnectionHandler.default.insert(connection:edge:after:)
        )
    }
}

public class PrependEdgeHandler: Handler {
    public static let `default` = PrependEdgeHandler()

    public init() {}

    public func update(store: inout RecordSourceProxy, fieldPayload: HandleFieldPayload) {
        updateEdge(
            store: &store,
            fieldPayload: fieldPayload,
            insertFn: ConnectionHandler.default.insert(connection:edge:before:)
        )
    }
}

public class AppendNodeHandler: Handler {
    public static let `default` = AppendNodeHandler()

    public init() {}

    public func update(store: inout RecordSourceProxy, fieldPayload: HandleFieldPayload) {
        updateNode(
            store: &store,
            fieldPayload: fieldPayload,
            insertFn: ConnectionHandler.default.insert(connection:edge:after:)
        )
    }
}

public class PrependNodeHandler: Handler {
    public static let `default` = PrependNodeHandler()

    public init() {}

    public func update(store: inout RecordSourceProxy, fieldPayload: HandleFieldPayload) {
        updateNode(
            store: &store,
            fieldPayload: fieldPayload,
            insertFn: ConnectionHandler.default.insert(connection:edge:before:)
        )
    }
}

private typealias InsertFn = (inout RecordProxy, RecordProxy, String?) -> Void

private func updateEdge(store: inout RecordSourceProxy, fieldPayload payload: HandleFieldPayload, insertFn: InsertFn) {
    guard let record = store[payload.dataID] else {
        return
    }

    guard case .array(let connections) = payload.handleArgs.connections else {
        preconditionFailure("MutationHandlers: Expected array of connection IDs to be specified.")
    }

    let serverEdges: [RecordProxy]
    if let serverEdge = record.getLinkedRecord(payload.fieldKey, args: payload.args) {
        serverEdges = [serverEdge]
    } else if let edges = record.getLinkedRecords(payload.fieldKey, args: payload.args) {
        serverEdges = edges.compactMap { $0 }
    } else {
        preconditionFailure("MutationHandlers: Expected the server edge to be non-null.")
    }

    for serverEdge in serverEdges {
        for connectionID in connections {
            guard case .string(let connectionID) = connectionID else {
                preconditionFailure("MutationHandlers: Expected connection ID to be a string.")
            }
            guard var connection = store[DataID(connectionID)] else {
                logger.warning("The connection with ID '\(connectionID, privacy: .public)' doesn't exist.")
                continue
            }

            guard let clientEdge = ConnectionHandler.default.buildConnectionEdge(&store, connection: &connection, edge: serverEdge) else {
                preconditionFailure("MutationHandlers: Failed to build the edge.")
            }

            insertFn(&connection, clientEdge, nil)
        }
    }
}

private func updateNode(store: inout RecordSourceProxy, fieldPayload payload: HandleFieldPayload, insertFn: InsertFn) {
    guard let record = store[payload.dataID] else {
        return
    }

    guard case .array(let connections) = payload.handleArgs.connections else {
        preconditionFailure("MutationHandlers: Expected array of connection IDs to be specified.")
    }
    guard case .string(let edgeTypeName) = payload.handleArgs.edgeTypeName else {
        preconditionFailure("MutationHandlers: Expected edge typename to be specified.")
    }

    let serverNodes: [RecordProxy]
    if let serverNode = record.getLinkedRecord(payload.fieldKey, args: payload.args) {
        serverNodes = [serverNode]
    } else if let nodes = record.getLinkedRecords(payload.fieldKey, args: payload.args) {
        serverNodes = nodes.compactMap { $0 }
    } else {
        preconditionFailure("MutationHandlers: Expected the target node to exist.")
    }

    for serverNode in serverNodes {
        for connectionID in connections {
            guard case .string(let connectionID) = connectionID else {
                preconditionFailure("MutationHandlers: Expected connection ID to be a string.")
            }
            guard var connection = store[DataID(connectionID)] else {
                logger.warning("The connection with ID '\(connectionID, privacy: .public)' doesn't exist.")
                continue
            }

            let clientEdge = ConnectionHandler.default.createEdge(&store, connection: connection, node: serverNode, type: edgeTypeName)

            insertFn(&connection, clientEdge, nil)
        }
    }
}
