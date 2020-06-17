import XCTest
import Nimble
@testable import Relay

class StorableTests: XCTestCase {
    func testStorageKeyPredefined() throws {
        let field = ReaderScalarField(name: "foo", storageKey: "foobar")
        expect(field.storageKey(from: ["a": "b"])) == "foobar"
    }

    func testStorageKeyNoArguments() throws {
        let field = ReaderScalarField(name: "foo", alias: "bar")
        expect(field.storageKey(from: ["a": "b"])) == "foo"
    }

    func testStorageKeyLiteralArguments() throws {
        let field = ReaderScalarField(name: "foo", args: [
            LiteralArgument(name: "a", value: 123),
            LiteralArgument(name: "b", value: true),
        ])
        expect(field.storageKey(from: ["a": "b"])) == "foo(a:123,b:true)"
    }

    func testStorageKeyVariableArguments() throws {
        let field = ReaderScalarField(name: "foo", args: [
            VariableArgument(name: "a", variableName: "c"),
            VariableArgument(name: "b", variableName: "d"),
        ])
        expect(field.storageKey(from: ["c": 1, "d": 2])) == "foo(a:1,b:2)"
    }
}
