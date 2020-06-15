import XCTest
@testable import Relay

fileprivate struct Pokemon: Readable, Hashable {
    var id: String
    var name: String?

    init(from data: SelectorData) {
        id = data.get(String.self, "id")
        name = data.get(String?.self, "name")
    }
}

class SelectorDataTests: XCTestCase {
    func testEmptyData() throws {
        let data = SelectorData()
        XCTAssertNil(data.get(String?.self, "someField"))
        XCTAssertNil(data.get([String]?.self, "someField"))
        XCTAssertNil(data.get([String?]?.self, "someField"))
        XCTAssertNil(data.get(SelectorData?.self, "someField"))
        XCTAssertNil(data.get([SelectorData]?.self, "someField"))
        XCTAssertNil(data.get([SelectorData?]?.self, "someField"))
        XCTAssertNil(data.get(Pokemon?.self, "someField"))
        XCTAssertNil(data.get([Pokemon]?.self, "someField"))
        XCTAssertNil(data.get([Pokemon?]?.self, "someField"))
    }

    func testAssignAndReadScalars() throws {
        var data = SelectorData()
        data.set("intField", scalar: 123)
        data.set("floatField", scalar: 1.234)
        data.set("stringField", scalar: "hello world")
        data.set("boolField", scalar: true)

        XCTAssertEqual(123, data.get(Int.self, "intField"))
        XCTAssertEqual(123, data.get(Int?.self, "intField"))

        XCTAssertEqual(1.234, data.get(Double.self, "floatField"))
        XCTAssertEqual(1.234, data.get(Double?.self, "floatField"))

        XCTAssertEqual("hello world", data.get(String.self, "stringField"))
        XCTAssertEqual("hello world", data.get(String?.self, "stringField"))

        XCTAssertTrue(data.get(Bool.self, "boolField"))
        XCTAssertTrue(data.get(Bool?.self, "boolField")!)
    }

    func testAssignAndReadScalarArrays() throws {
        var data = SelectorData()
        data.set("intsField", scalar: [123, 456, nil])
        data.set("floatsField", scalar: [1.234, 56.78])
        data.set("stringsField", scalar: ["hello", "world"])
        data.set("boolsField", scalar: [nil, true, false])

        XCTAssertEqual([123, 456, nil], data.get([Int?].self, "intsField"))
        XCTAssertEqual([1.234, 56.78], data.get([Double].self, "floatsField"))
        XCTAssertEqual([1.234, 56.78], data.get([Double?].self, "floatsField"))
        XCTAssertEqual(["hello", "world"], data.get([String].self, "stringsField"))
        XCTAssertEqual(["hello", "world"], data.get([String?].self, "stringsField"))
        XCTAssertEqual([nil, true, false], data.get([Bool?].self, "boolsField"))
    }

    func testAssignAndReadObject() throws {
        var pokemonData = SelectorData()
        pokemonData.set("id", scalar: "1234")
        pokemonData.set("name", scalar: "Bulbasaur")

        var data = SelectorData()
        data.set("pokemon", object: pokemonData)

        let pokemon = data.get(Pokemon.self, "pokemon")

        XCTAssertEqual("1234", pokemon.id)
        XCTAssertEqual("Bulbasaur", pokemon.name)

        let pokemon2 = data.get(Pokemon?.self, "pokemon")
        XCTAssertEqual(pokemon, pokemon2)
    }

    func testReadNilObject() throws {
        var data = SelectorData()
        data.set("pokemon", object: nil)

        XCTAssertNil(data.get(Pokemon?.self, "pokemon"))
    }

    func testAssignAndReadObjects() throws {
        var pokemonData = SelectorData()
        pokemonData.set("id", scalar: "1234")
        pokemonData.set("name", scalar: "Bulbasaur")

        var pokemonData2 = SelectorData()
        pokemonData2.set("id", scalar: "5678")
        pokemonData2.set("name", scalar: "Charmander")

        var data = SelectorData()
        data.set("pokemons", objects: [pokemonData, nil, pokemonData2])

        let pokemons = data.get([Pokemon?].self, "pokemons")
        XCTAssertEqual("1234", pokemons[0]?.id)
        XCTAssertNil(pokemons[1])
        XCTAssertEqual("5678", pokemons[2]?.id)

        let pokemons2 = data.get([Pokemon?]?.self, "pokemons")
        XCTAssertEqual(pokemons, pokemons2)

        data.set("pokemons", objects: [pokemonData, pokemonData2])

        let pokemons3 = data.get([Pokemon].self, "pokemons")
        XCTAssertEqual(["1234", "5678"], pokemons3.map(\.id))

        let pokemons4 = data.get([Pokemon]?.self, "pokemons")
        XCTAssertEqual(pokemons3, pokemons4)
    }

    func testAssignAndReadFragmentPointer() throws {
        var data = SelectorData()
        data.set(fragment: "PokemonListRow_pokemon",
                 variables: ["a": "b"],
                 dataID: "record_123",
                 owner: PokemonListQuery.createDescriptor(variables: ["a": "b"]).request)

        let pointer = data.get(fragment: "PokemonListRow_pokemon")
        XCTAssertEqual(["a": "b"], pointer.variables)
        XCTAssertEqual("record_123", pointer.id)
    }

    func testGetByPath() throws {
        var pokemonData = SelectorData()
        pokemonData.set("id", scalar: "1234")
        pokemonData.set("name", scalar: "Bulbasaur")

        var edgeData = SelectorData()
        edgeData.set("node", object: pokemonData)

        var data = SelectorData()
        data.set("edges", objects: [edgeData])

        let pokemon = data.get(path: ["edges", 0, "node"]) as! SelectorData
        XCTAssertEqual("1234", pokemon.get(String.self, "id"))
    }
}
