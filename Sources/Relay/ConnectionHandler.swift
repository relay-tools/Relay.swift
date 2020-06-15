import Foundation

private let nextEdgeIndex = "__connection_next_edge_index"

public class ConnectionHandler: Handler {
    public static let `default` = ConnectionHandler()

    private let config: ConnectionConfig

    init(config: ConnectionConfig = .default) {
        self.config = config
    }

    public func update(store: inout RecordSourceProxy, fieldPayload payload: HandleFieldPayload) {
        guard var record = store[payload.dataID] else {
            return
        }

        guard let serverConnection = record.getLinkedRecord(payload.fieldKey) else {
            record[payload.handle] = nil
            return
        }

        let serverPageInfo = serverConnection.getLinkedRecord(config.pageInfo)
        let clientConnectionID = record.dataID.clientID(storageKey: payload.handleKey)

        guard record.getLinkedRecord(payload.handleKey) != nil, let clientConnection = store[clientConnectionID] else {
            var connection = store.create(dataID: clientConnectionID, typeName: serverConnection.typeName)
            connection[nextEdgeIndex] = 0
            connection.copyFields(from: serverConnection)

            if let serverEdges = serverConnection.getLinkedRecords(config.edges) {
                connection.setLinkedRecords(config.edges, records: serverEdges.map { edge in
                    buildConnectionEdge(&store, connection: &connection, edge: edge)
                })
            }

            record.setLinkedRecord(payload.handleKey, record: connection)

            var clientPageInfo = store.create(dataID: connection.dataID.clientID(storageKey: config.pageInfo), typeName: config.pageInfoType)
            clientPageInfo[config.hasNextPage] = false
            clientPageInfo[config.hasPreviousPage] = false
            clientPageInfo[config.endCursor] = nil
            clientPageInfo[config.startCursor] = nil
            if let serverPageInfo = serverPageInfo {
                clientPageInfo.copyFields(from: serverPageInfo)
            }
            connection.setLinkedRecord(config.pageInfo, record: clientPageInfo)

            return
        }

        var connection = clientConnection
        let clientPageInfo = connection.getLinkedRecord(config.pageInfo)

        let serverEdges = serverConnection.getLinkedRecords(config.edges)?.map { edge in
            buildConnectionEdge(&store, connection: &connection, edge: edge)
        }

        let prevEdges = connection.getLinkedRecords(config.edges)
        let prevPageInfo = connection.getLinkedRecord(config.pageInfo)
        connection.copyFields(from: serverConnection)

        if let prevEdges = prevEdges {
            connection.setLinkedRecords(config.edges, records: prevEdges)
        }
        if let prevPageInfo = prevPageInfo {
            connection.setLinkedRecord(config.pageInfo, record: prevPageInfo)
        }

        var nextEdges: [RecordProxy?]?
        let args = payload.args

        var updated = true
        if let prevEdges = prevEdges, let serverEdges = serverEdges {
            if let after = args.after {
                if let clientPageInfo = clientPageInfo, after == (clientPageInfo[config.endCursor] as? VariableValueConvertible)?.variableValue {
                    var nodeIDs = Set<DataID>()
                    var edges: [RecordProxy?] = []
                    mergeEdges(from: prevEdges, to: &edges, nodeIDs: &nodeIDs)
                    mergeEdges(from: serverEdges, to: &edges, nodeIDs: &nodeIDs)
                    nextEdges = edges
                } else {
                    NSLog("Relay: Unexpected after cursor \(after), edges must be fetched from the end of the list (\(String(describing: clientPageInfo?[config.endCursor]))")
                    return
                }
            } else if let before = args.before {
                if let clientPageInfo = clientPageInfo, before == (clientPageInfo[config.startCursor] as? VariableValueConvertible)?.variableValue {
                    var nodeIDs = Set<DataID>()
                    var edges: [RecordProxy?] = []
                    mergeEdges(from: serverEdges, to: &edges, nodeIDs: &nodeIDs)
                    mergeEdges(from: prevEdges, to: &edges, nodeIDs: &nodeIDs)
                    nextEdges = edges
                } else {
                    NSLog("Relay: Unexpected before cursor \(before), edges must be fetched from the beginning of the list (\(String(describing: clientPageInfo?[config.startCursor]))")
                    return
                }
            } else {
                nextEdges = serverEdges
            }
        } else if let serverEdges = serverEdges {
            nextEdges = serverEdges
        } else {
            nextEdges = prevEdges
            updated = false
        }

        if let nextEdges = nextEdges, updated {
            connection.setLinkedRecords(config.edges, records: nextEdges)
        }

        if var clientPageInfo = clientPageInfo, let serverPageInfo = serverPageInfo {
            let after = args.after
            let hasAfter = after != nil && after != .null
            let before = args.before
            let hasBefore = before != nil && before != .null

            if !hasAfter && !hasBefore {
                clientPageInfo.copyFields(from: serverPageInfo)
            } else if hasBefore || (!hasAfter && args.last != nil) {
                clientPageInfo[config.hasPreviousPage] = (serverPageInfo[config.hasPreviousPage] as! NSNumber).boolValue
                if let startCursor = serverPageInfo[config.startCursor] as? String {
                    clientPageInfo[config.startCursor] = startCursor
                }
            } else if hasAfter || (!hasBefore && args.first != nil) {
                clientPageInfo[config.hasNextPage] = (serverPageInfo[config.hasNextPage] as! NSNumber).boolValue
                if let endCursor = serverPageInfo[config.endCursor] as? String {
                    clientPageInfo[config.endCursor] = endCursor
                }
            }
        }
    }

    public func buildConnectionEdge(_ store: inout RecordSourceProxy, connection: inout RecordProxy, edge: RecordProxy?) -> RecordProxy? {
        guard let edge = edge else { return nil }

        guard let edgeIndex = connection[nextEdgeIndex] as? Int else {
            preconditionFailure("Expected \(nextEdgeIndex) to be a number, got \(String(describing: connection[nextEdgeIndex]))")
        }

        let edgeID = connection.dataID.clientID(storageKey: config.edges, index: edgeIndex)
        var connectionEdge = store.create(dataID: edgeID, typeName: edge.typeName)
        connectionEdge.copyFields(from: edge)
        connection[nextEdgeIndex] = edgeIndex + 1
        return connectionEdge
    }

    func mergeEdges(from sourceEdges: [RecordProxy?], to targetEdges: inout [RecordProxy?], nodeIDs: inout Set<DataID>) {
        for edge in sourceEdges {
            guard let edge = edge else {
                continue
            }

            if let nodeID = edge.getLinkedRecord(config.node)?.dataID {
                if nodeIDs.contains(nodeID) {
                    continue
                }

                nodeIDs.insert(nodeID)
            }

            targetEdges.append(edge)
        }
    }

    public func getConnection(_ record: RecordProxy, key: String, filters: VariableDataConvertible? = nil) -> RecordProxy? {
        record.getLinkedRecord(getRelayHandleKey(handleName: "connection", key: key), args: filters)
    }

    public func createEdge(_ store: inout RecordSourceProxy, connection: inout RecordProxy, node: RecordProxy, type edgeType: String) -> RecordProxy {
        let edgeID = connection.dataID.clientID(storageKey: node.dataID.rawValue)
        var edge = store[edgeID] ?? store.create(dataID: edgeID, typeName: edgeType)
        edge.setLinkedRecord(config.node, record: node)
        return edge
    }

    public func insert(connection: inout RecordProxy, edge newEdge: RecordProxy, before cursor: String?) {
        guard let edges = connection.getLinkedRecords(config.edges) else {
            connection.setLinkedRecords(config.edges, records: [newEdge])
            return
        }

        var nextEdges = edges
        if let cursor = cursor, let cursorIndex = edges.firstIndex(where: { ($0?[config.cursor] as? String) == cursor }) {
            nextEdges.insert(newEdge, at: cursorIndex)
        } else {
            nextEdges.insert(newEdge, at: 0)
        }

        connection.setLinkedRecords(config.edges, records: nextEdges)
    }

    public func insert(connection: inout RecordProxy, edge newEdge: RecordProxy, after cursor: String?) {
        guard let edges = connection.getLinkedRecords(config.edges) else {
            connection.setLinkedRecords(config.edges, records: [newEdge])
            return
        }

        var nextEdges = edges
        if let cursor = cursor, let cursorIndex = edges.firstIndex(where: { ($0?[config.cursor] as? String) == cursor }) {
            nextEdges.insert(newEdge, at: cursorIndex + 1)
        } else {
            nextEdges.append(newEdge)
        }

        connection.setLinkedRecords(config.edges, records: nextEdges)
    }

    public func delete(connection: inout RecordProxy, nodeID: DataID) {
        guard let edges = connection.getLinkedRecords(config.edges) else {
            return
        }

        let nextEdges = edges.filter { edge in
            edge?.getLinkedRecord(config.node)?.dataID != nodeID
        }
        connection.setLinkedRecords(config.edges, records: nextEdges)
    }
}
