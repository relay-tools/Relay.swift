import XCTest
import SnapshotTesting
import Nimble
@testable import Relay

class VariableDataTests: XCTestCase {
    func testIsEmpty() throws {
        var data: VariableData = [:]
        expect(data.isEmpty).to(beTrue())

        data.id = .string("foo_123")
        expect(data.isEmpty).to(beFalse())

        data.id = nil
        expect(data.isEmpty).to(beTrue())
    }

    func testCreateFromDictionary() throws {
        let data: VariableData = [
            "null": nil as String?,
            "int": 123,
            "float": 1.234,
            "string": "hello",
            "bool": true,
            "object": [
                "id": "123",
                "name": "foo",
            ],
            "array": [123, nil, 456],
        ]
        expect(data.isEmpty).to(beFalse())
        assertSnapshot(matching: data, as: .dump)

        let data2 = VariableData([
            "null": nil as String?,
            "int": 123,
            "float": 1.234,
            "string": "hello",
            "bool": true,
            "object": [
                "id": "123",
                "name": "foo",
            ],
            "array": [123, nil, 456],
        ])
        expect(data2) == data
    }

    func testEncodeToJSON() throws {
        let data: VariableData = [
            "null": nil as String?,
            "int": 123,
            "float": 1.234,
            "string": "hello",
            "bool": true,
            "object": [
                "id": "123",
                "name": "foo",
                "data": [
                    "foo": "bar",
                ].variableValue,
            ] as VariableData,
            "array": [123, nil, 456],
            "objectArray": [
                ["name": "Dave"],
                ["name": "Anne"],
            ],
        ]

        let encoded = try JSONEncoder().encode(data)
        let decoded = try JSONSerialization.jsonObject(with: encoded, options: []) as! NSDictionary

        assertSnapshot(matching: decoded, as: .description)
    }

    func testDescriptionEmpty() throws {
        let data: VariableData = [:]
        expect("\(data)").to(beEmpty())
    }

    func testDescriptionSimple() throws {
        let data: VariableData = ["a": "b", "c": "d"]
        assertSnapshot(matching: data, as: .description)
    }

    func testDescriptionComplex() throws {
        let data: VariableData = [
            "null": nil as String?,
            "int": 123,
            "float": 1.234,
            "string": "hello",
            "bool": true,
            "object": [
                "id": "123",
                "name": "foo",
                "data": [
                    "foo": "bar",
                ].variableValue,
            ] as VariableData,
            "array": [123, nil, 456],
            "objectArray": [
                ["name": "Dave"],
                ["name": "Anne"],
            ],
        ]
        assertSnapshot(matching: data, as: .description)
    }

    func testInnerDescriptionEmpty() throws {
        let data: VariableData = [:]
        expect(data.innerDescription).to(beEmpty())
    }

    func testInnerDescriptionSimple() throws {
        let data: VariableData = ["a": "b", "c": "d"]
        assertSnapshot(matching: data.innerDescription, as: .lines)
    }

    func testInnerDescriptionComplex() throws {
        let data: VariableData = [
            "null": nil as String?,
            "int": 123,
            "float": 1.234,
            "string": "hello",
            "bool": true,
            "object": [
                "id": "123",
                "name": "foo",
                "data": [
                    "foo": "bar",
                ].variableValue,
            ] as VariableData,
            "array": [123, nil, 456],
            "objectArray": [
                ["name": "Dave"],
                ["name": "Anne"],
            ],
        ]
        assertSnapshot(matching: data.innerDescription, as: .lines)
    }

    func testMerge() throws {
        var data: VariableData = ["a": "b", "c": "d"]
        data.merge(["a": "g", "b": "h"])

        expect(data) == ["a": "g", "b": "h", "c": "d"]
    }
}
