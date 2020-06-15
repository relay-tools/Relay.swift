import XCTest
@testable import Relay

class RecordTests: XCTestCase {
    func testRootRecord() throws {
        XCTAssertEqual("client:root", Record.root.dataID)
        XCTAssertEqual("__Root", Record.root.typename)
        XCTAssertTrue(Record.root.fields.isEmpty)
    }

    func testCreateEmptyRecord() throws {
        let record = Record(dataID: "record_123", typename: "Pokemon")
        XCTAssertEqual("record_123", record.dataID)
        XCTAssertEqual("Pokemon", record.typename)
        XCTAssertTrue(record.fields.isEmpty)
    }

    func testReadEmptyScalarField() throws {
        let record = Record(dataID: "record_123", typename: "Pokemon")
        XCTAssertNil(record["someField"])
    }

    func testAssignAndReadScalars() throws {
        var record = Record(dataID: "record_123", typename: "Pokemon")
        record["nullField"] = NSNull()
        record["intField"] = 123
        record["floatField"] = 1.234
        record["stringField"] = "hello world"
        record["boolField"] = true

        XCTAssertEqual(NSNull(), record["nullField"] as! NSNull)
        XCTAssertEqual(123, record["intField"] as! Int)
        XCTAssertEqual(1.234, record["floatField"] as! Double)
        XCTAssertEqual("hello world", record["stringField"] as! String)
        XCTAssertTrue(record["boolField"] as! Bool)
    }

    func testAssignAndReadScalarArrays() throws {
        var record = Record(dataID: "record_123", typename: "Pokemon")
        record["intsField"] = [123, 456, 789, NSNull()]
        record["floatsField"] = [1.234, NSNull(), 56.78]
        record["stringsField"] = [NSNull(), "hello", "world"]
        record["boolsField"] = [NSNull(), true, false]

        let ints = record["intsField"] as! [Any]
        XCTAssertEqual(4, ints.count)
        XCTAssertEqual(456, ints[1] as! Int)
        XCTAssertEqual(NSNull(), ints[3] as! NSNull)

        let floats = record["floatsField"] as! [Any]
        XCTAssertEqual(3, floats.count)
        XCTAssertEqual(56.78, floats[2] as! Double)
        XCTAssertEqual(NSNull(), floats[1] as! NSNull)

        let strings = record["stringsField"] as! [Any]
        XCTAssertEqual(3, strings.count)
        XCTAssertEqual("world", strings[2] as! String)
        XCTAssertEqual(NSNull(), strings[0] as! NSNull)

        let bools = record["boolsField"] as! [Any]
        XCTAssertEqual(3, bools.count)
        XCTAssertFalse(bools[2] as! Bool)
        XCTAssertEqual(NSNull(), bools[0] as! NSNull)
    }

    func testRemoveScalarValue() throws {
        var record = Record(dataID: "record_123", typename: "Pokemon")
        record["someField"] = "hello"
        record["someField"] = nil

        XCTAssertNil(record["someField"])
    }

    func testGetLinkedRecordIDEmpty() throws {
        let record = Record(dataID: "record_123", typename: "Pokemon")
        XCTAssertNil(record.getLinkedRecordID("child") as Any?)
    }

    func testGetLinkedRecordIDNull() throws {
        var record = Record(dataID: "record_123", typename: "Pokemon")
        record["child"] = NSNull()
        XCTAssertNotNil(record.getLinkedRecordID("child") as Any?)
        XCTAssertNil(record.getLinkedRecordID("child")!)
    }

    func testGetLinkedRecordIDPresent() throws {
        var record = Record(dataID: "record_123", typename: "Pokemon")
        record.setLinkedRecordID("child", "record_456")
        XCTAssertNotNil(record.getLinkedRecordID("child") as Any?)
        XCTAssertNotNil(record.getLinkedRecordID("child")!)
        XCTAssertEqual("record_456", record.getLinkedRecordID("child"))
    }

    func testGetLinkedRecordIDsEmpty() throws {
        let record = Record(dataID: "record_123", typename: "Pokemon")
        XCTAssertNil(record.getLinkedRecordIDs("child") as Any?)
    }

    func testGetLinkedRecordIDsNull() throws {
        var record = Record(dataID: "record_123", typename: "Pokemon")
        record["child"] = NSNull()
        XCTAssertNotNil(record.getLinkedRecordIDs("child") as Any?)
        XCTAssertNil(record.getLinkedRecordIDs("child")!)
    }

    func testGetLinkedRecordIDsPresent() throws {
        var record = Record(dataID: "record_123", typename: "Pokemon")
        record.setLinkedRecordIDs("child", ["record_456", nil, "record_789"])
        XCTAssertNotNil(record.getLinkedRecordIDs("child") as Any?)
        XCTAssertNotNil(record.getLinkedRecordIDs("child")!)
        XCTAssertEqual(["record_456", nil, "record_789"], record.getLinkedRecordIDs("child"))
    }

    func testCopyFields() throws {
        var record1 = Record(dataID: "record_123", typename: "Pokemon")
        record1["field1"] = "hello"
        record1["field2"] = "world"
        record1["field3"] = NSNull()
        record1.setLinkedRecordID("child1", "record_456")
        record1.setLinkedRecordID("child2", "record_789")
        record1.setLinkedRecordIDs("children1", ["record_234", nil])
        record1.setLinkedRecordIDs("children2", ["record_345"])

        var dest = Record(dataID: .generateClientID(), typename: "Pokemon")
        dest["field1"] = "foo"
        dest["field4"] = "bar"
        dest.setLinkedRecordID("child1", "record_890")
        dest.setLinkedRecordID("child3", "record_567")
        dest.setLinkedRecordIDs("children1", [nil, nil, nil])
        dest.setLinkedRecordIDs("children3", [nil, "record_678"])

        let source = record1 // ensure source record doesn't get mutated
        dest.copyFields(from: source)

        XCTAssertNotEqual("record_123", dest.dataID)
        XCTAssertEqual(dest.fields, [
            "field1": .string("hello"),
            "field2": .string("world"),
            "field3": .null,
            "field4": .string("bar"),
            "child1": .linkedRecord("record_456"),
            "child2": .linkedRecord("record_789"),
            "child3": .linkedRecord("record_567"),
            "children1": .linkedRecords(["record_234", nil]),
            "children2": .linkedRecords(["record_345"]),
            "children3": .linkedRecords([nil, "record_678"]),
        ])
    }

    func testUpdate() throws {
        var record1 = Record(dataID: "record_123", typename: "Pokemon")
        record1["field1"] = "hello"
        record1["field2"] = "world"
        record1["field3"] = NSNull()
        record1.setLinkedRecordID("child1", "record_456")
        record1.setLinkedRecordID("child2", "record_789")
        record1.setLinkedRecordIDs("children1", ["record_234", nil])
        record1.setLinkedRecordIDs("children2", ["record_345"])

        var dest = Record(dataID: "record_123", typename: "Pokemon")
        dest["field1"] = "foo"
        dest["field4"] = "bar"
        dest.setLinkedRecordID("child1", "record_890")
        dest.setLinkedRecordID("child3", "record_567")
        dest.setLinkedRecordIDs("children1", [nil, nil, nil])
        dest.setLinkedRecordIDs("children3", [nil, "record_678"])

        let source = record1 // ensure source record doesn't get mutated
        dest.update(from: source)

        XCTAssertEqual(dest.fields, [
            "field1": .string("hello"),
            "field2": .string("world"),
            "field3": .null,
            "field4": .string("bar"),
            "child1": .linkedRecord("record_456"),
            "child2": .linkedRecord("record_789"),
            "child3": .linkedRecord("record_567"),
            "children1": .linkedRecords(["record_234", nil]),
            "children2": .linkedRecords(["record_345"]),
            "children3": .linkedRecords([nil, "record_678"]),
        ])
    }
}
