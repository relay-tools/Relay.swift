import XCTest
import Nimble
@testable import Relay

class RecordTests: XCTestCase {
    func testRootRecord() throws {
        expect(Record.root.dataID) == "client:root"
        expect(Record.root.typename) == "__Root"
        expect(Record.root.fields).to(beEmpty())
    }

    func testCreateEmptyRecord() throws {
        let record = Record(dataID: "record_123", typename: "Pokemon")
        expect(record.dataID) == "record_123"
        expect(record.typename) == "Pokemon"
        expect(record.fields).to(beEmpty())
    }

    func testReadEmptyScalarField() throws {
        let record = Record(dataID: "record_123", typename: "Pokemon")
        expect(record["someField"]).to(beNil())
    }

    func testAssignAndReadScalars() throws {
        var record = Record(dataID: "record_123", typename: "Pokemon")
        record["nullField"] = NSNull()
        record["intField"] = 123
        record["floatField"] = 1.234
        record["stringField"] = "hello world"
        record["boolField"] = true

        expect(record["nullField"] as? NSNull) == NSNull()
        expect(record["intField"] as? Int) == 123
        expect(record["floatField"] as? Double) == 1.234
        expect(record["stringField"] as? String) == "hello world"
        expect(record["boolField"] as? Bool).to(beTrue())
    }

    func testAssignAndReadScalarArrays() throws {
        var record = Record(dataID: "record_123", typename: "Pokemon")
        record["intsField"] = [123, 456, 789, NSNull()]
        record["floatsField"] = [1.234, NSNull(), 56.78]
        record["stringsField"] = [NSNull(), "hello", "world"]
        record["boolsField"] = [NSNull(), true, false]

        let ints = record["intsField"] as! [Any]
        expect(ints).to(haveCount(4))
        expect(ints[1] as? Int) == 456
        expect(ints[3] as? NSNull) == NSNull()

        let floats = record["floatsField"] as! [Any]
        expect(floats).to(haveCount(3))
        expect(floats[2] as? Double) == 56.78
        expect(floats[1] as? NSNull) == NSNull()

        let strings = record["stringsField"] as! [Any]
        expect(strings).to(haveCount(3))
        expect(strings[2] as? String) == "world"
        expect(strings[0] as? NSNull) == NSNull()

        let bools = record["boolsField"] as! [Any]
        expect(bools).to(haveCount(3))
        expect(bools[2] as? Bool).to(beFalse())
        expect(bools[0] as? NSNull) == NSNull()
    }

    func testRemoveScalarValue() throws {
        var record = Record(dataID: "record_123", typename: "Pokemon")
        record["someField"] = "hello"
        record["someField"] = nil

        expect(record["someField"]).to(beNil())
    }

    func testGetLinkedRecordIDEmpty() throws {
        let record = Record(dataID: "record_123", typename: "Pokemon")
        expect(record.getLinkedRecordID("child")).to(beNil())
    }

    func testGetLinkedRecordIDNull() throws {
        var record = Record(dataID: "record_123", typename: "Pokemon")
        record["child"] = NSNull()
        expect(record.getLinkedRecordID("child")).notTo(beNil())
        expect(record.getLinkedRecordID("child")!).to(beNil())
    }

    func testGetLinkedRecordIDPresent() throws {
        var record = Record(dataID: "record_123", typename: "Pokemon")
        record.setLinkedRecordID("child", "record_456")
        expect(record.getLinkedRecordID("child")).notTo(beNil())
        expect(record.getLinkedRecordID("child")!).notTo(beNil())
        expect(record.getLinkedRecordID("child")) == "record_456"
    }

    func testGetLinkedRecordIDsEmpty() throws {
        let record = Record(dataID: "record_123", typename: "Pokemon")
        expect(record.getLinkedRecordIDs("child")).to(beNil())
    }

    func testGetLinkedRecordIDsNull() throws {
        var record = Record(dataID: "record_123", typename: "Pokemon")
        record["child"] = NSNull()
        expect(record.getLinkedRecordIDs("child")).notTo(beNil())
        expect(record.getLinkedRecordIDs("child")!).to(beNil())
    }

    func testGetLinkedRecordIDsPresent() throws {
        var record = Record(dataID: "record_123", typename: "Pokemon")
        record.setLinkedRecordIDs("child", ["record_456", nil, "record_789"])
        expect(record.getLinkedRecordIDs("child")).notTo(beNil())
        expect(record.getLinkedRecordIDs("child")!).notTo(beNil())
        expect(record.getLinkedRecordIDs("child")) == ["record_456", nil, "record_789"]
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

        expect(dest.dataID) != "record_123"
        expect(dest.fields) == [
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
        ]
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

        expect(dest.fields) == [
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
        ]
    }
}
