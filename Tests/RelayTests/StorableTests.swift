import XCTest
@testable import Relay

class StorableTests: XCTestCase {
    func testStorageKeyPredefined() throws {
        let field = ReaderScalarField(name: "foo", storageKey: "foobar")
        XCTAssertEqual("foobar", field.storageKey(from: ["a": "b"]))
    }

    func testStorageKeyNoArguments() throws {
        let field = ReaderScalarField(name: "foo", alias: "bar")
        XCTAssertEqual("foo", field.storageKey(from: ["a": "b"]))
    }

    func testStorageKeyLiteralArguments() throws {
        let field = ReaderScalarField(name: "foo", args: [
            LiteralArgument(name: "a", value: 123),
            LiteralArgument(name: "b", value: true),
        ])
        XCTAssertEqual("foo(a:123,b:true)", field.storageKey(from: ["a": "b"]))
    }

    func testStorageKeyVariableArguments() throws {
        let field = ReaderScalarField(name: "foo", args: [
            VariableArgument(name: "a", variableName: "c"),
            VariableArgument(name: "b", variableName: "d"),
        ])
        XCTAssertEqual("foo(a:1,b:2)", field.storageKey(from: ["c": 1, "d": 2]))
    }
}
