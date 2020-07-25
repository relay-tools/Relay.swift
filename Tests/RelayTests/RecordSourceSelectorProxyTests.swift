import XCTest
import Nimble
import SnapshotTesting
@testable import Relay
@testable import RelayTestHelpers

class RecordSourceSelectorProxyTests: XCTestCase {
    private var environment: MockEnvironment!
    private var mutator: RecordSourceMutator!
    private var store: RecordSourceSelectorProxy!

    override func setUpWithError() throws {
        environment = MockEnvironment()
        try environment.cachePayload(CurrentUserToDoListQuery(), initialPayload)

        // this is a lot of set up to simulate a mutation up to the point where we have the
        // RecordSourceSelectorProxy
        let mutation = ChangeTodoStatusMutation(input: .init(complete: true, id: "VG9kbzox", userId: "me"))
        let responseDict = try JSONSerialization.jsonObject(with: mutationResponse.data(using: .utf8)!, options: []) as! [String: Any]
        let response = try! GraphQLResponse(dictionary: responseDict)
        let operation = mutation.createDescriptor(dataID: .generateClientID())
        let selector = operation.root
        var recordSource = DefaultRecordSource()
        recordSource[selector.dataID] = Record(dataID: selector.dataID, typename: Record.root.typename)
        let responsePayload = ResponseNormalizer.normalize(
            recordSource: recordSource,
            selector: selector,
            data: response.data!,
            request: operation.request)
        
        mutator = RecordSourceMutator(base: environment.store.recordSource, sink: responsePayload.source)
        let sourceProxy = DefaultRecordSourceProxy(mutator: mutator, handlerProvider: DefaultHandlerProvider())
        store = DefaultRecordSourceSelectorProxy(mutator: mutator, recordSource: sourceProxy, readSelector: operation.fragment)
    }

    func testGetRootField() throws {
        let changeTodoStatus = store.getRootField("changeTodoStatus")
        expect(changeTodoStatus).notTo(beNil())

        let todo = changeTodoStatus!.getLinkedRecord("todo")
        expect(todo).notTo(beNil())

        expect(todo!["id"] as? String) == "VG9kbzox"
        expect(todo!["complete"] as? Int) == 1
    }
}

private let initialPayload = """
{
"data": {
"user": {
"id": "VXNlcjptZQ==",
"todos": {
"edges": [
  {
    "node": {
      "__typename": "Todo",
      "id": "VG9kbzow",
      "complete": true,
      "text": "Taste JavaScript"
    },
    "cursor": "YXJyYXljb25uZWN0aW9uOjA="
  },
  {
    "node": {
      "__typename": "Todo",
      "id": "VG9kbzox",
      "complete": false,
      "text": "Buy a unicorn"
    },
    "cursor": "YXJyYXljb25uZWN0aW9uOjE="
  }
],
"pageInfo": {
  "endCursor": "YXJyYXljb25uZWN0aW9uOjE=",
  "hasNextPage": false
}
}
}
}
}
"""

private let mutationResponse = """
{
  "data": {
    "changeTodoStatus": {
      "todo": {
        "id": "VG9kbzox",
        "complete": true
      }
    }
  }
}
"""
