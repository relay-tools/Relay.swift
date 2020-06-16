import XCTest
@testable import Relay

class VariableDataTests: XCTestCase {
    func testIsEmpty() throws {
        var data: VariableData = [:]
        XCTAssertTrue(data.isEmpty)

        data.id = .string("foo_123")
        XCTAssertFalse(data.isEmpty)

        data.id = nil
        XCTAssertTrue(data.isEmpty)
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

        XCTAssertFalse(data.isEmpty)
        XCTAssertEqual(.null, data.null)
        XCTAssertEqual(.int(123), data.int)
        XCTAssertEqual(.float(1.234), data.float)
        XCTAssertEqual(.string("hello"), data.string)
        XCTAssertEqual(.bool(true), data.bool)
        XCTAssertEqual(.object(["id": "123", "name": "foo"]), data.object)
        XCTAssertEqual(.array([.int(123), .null, .int(456)]), data.array)

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

        XCTAssertEqual(data, data2)
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

        NSLog("decoded: \(decoded)")

        XCTAssertEqual([
            "null": NSNull(),
            "int": 123,
            "float": 1.234,
            "string": "hello",
            "bool": true,
            "object": [
                "id": "123",
                "name": "foo",
                "data": [
                    "foo": "bar",
                ],
            ] as [String: Any],
            "array": [123, NSNull(), 456],
            "objectArray": [
                ["name": "Dave"],
                ["name": "Anne"],
            ],
        ], decoded)
    }

    func testDescriptionEmpty() throws {
        let data: VariableData = [:]
        XCTAssertEqual("", "\(data)")
    }

    func testDescriptionSimple() throws {
        let data: VariableData = ["a": "b", "c": "d"]
        XCTAssertEqual("{a:\"b\",c:\"d\"}", "\(data)")
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

        XCTAssertEqual("{array:[123,null,456],bool:true,float:1.234,int:123,null:null,object:{data:{foo:\"bar\"},id:\"123\",name:\"foo\"},objectArray:[{name:\"Dave\"},{name:\"Anne\"}],string:\"hello\"}", "\(data)")
    }

    func testInnerDescriptionEmpty() throws {
        let data: VariableData = [:]
        XCTAssertEqual("", data.innerDescription)
    }

    func testInnerDescriptionSimple() throws {
        let data: VariableData = ["a": "b", "c": "d"]
        XCTAssertEqual("a:\"b\",c:\"d\"", data.innerDescription)
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

        XCTAssertEqual("array:[123,null,456],bool:true,float:1.234,int:123,null:null,object:{data:{foo:\"bar\"},id:\"123\",name:\"foo\"},objectArray:[{name:\"Dave\"},{name:\"Anne\"}],string:\"hello\"", data.innerDescription)
    }

    func testMerge() throws {
        var data: VariableData = ["a": "b", "c": "d"]
        data.merge(["a": "g", "b": "h"])

        XCTAssertEqual(["a": "g", "b": "h", "c": "d"], data)
    }
}
