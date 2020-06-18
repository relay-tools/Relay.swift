import XCTest
import SnapshotTesting
import Nimble
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
        expect(data.get(String?.self, "someField")).to(beNil())
        expect(data.get([String]?.self, "someField")).to(beNil())
        expect(data.get([String?]?.self, "someField")).to(beNil())
        expect(data.get(SelectorData?.self, "someField")).to(beNil())
        expect(data.get([SelectorData]?.self, "someField")).to(beNil())
        expect(data.get([SelectorData?]?.self, "someField")).to(beNil())
        expect(data.get(Pokemon?.self, "someField")).to(beNil())
        expect(data.get([Pokemon]?.self, "someField")).to(beNil())
        expect(data.get([Pokemon?]?.self, "someField")).to(beNil())
    }

    func testAssignAndReadScalars() throws {
        var data = SelectorData()
        data.set("intField", scalar: 123)
        data.set("floatField", scalar: 1.234)
        data.set("stringField", scalar: "hello world")
        data.set("boolField", scalar: true)

        expect(data.get(Int.self, "intField")) == 123
        expect(data.get(Int?.self, "intField")) == 123

        expect(data.get(Double.self, "floatField")) == 1.234
        expect(data.get(Double?.self, "floatField")) == 1.234

        expect(data.get(String.self, "stringField")) == "hello world"
        expect(data.get(String?.self, "stringField")) == "hello world"

        expect(data.get(Bool.self, "boolField")).to(beTrue())
        expect(data.get(Bool?.self, "boolField")).to(beTrue())
    }

    func testAssignAndReadScalarArrays() throws {
        var data = SelectorData()
        data.set("intsField", scalar: [123, 456, nil])
        data.set("floatsField", scalar: [1.234, 56.78])
        data.set("stringsField", scalar: ["hello", "world"])
        data.set("boolsField", scalar: [nil, true, false])

        expect(data.get([Int?].self, "intsField")) == [123, 456, nil]
        expect(data.get([Double].self, "floatsField")) == [1.234, 56.78]
        expect(data.get([Double?].self, "floatsField")) == [1.234, 56.78]
        expect(data.get([String].self, "stringsField")) == ["hello", "world"]
        expect(data.get([String?].self, "stringsField")) == ["hello", "world"]
        expect(data.get([Bool?].self, "boolsField")) == [nil, true, false]
    }

    func testAssignAndReadObject() throws {
        var pokemonData = SelectorData()
        pokemonData.set("id", scalar: "1234")
        pokemonData.set("name", scalar: "Bulbasaur")

        var data = SelectorData()
        data.set("pokemon", object: pokemonData)

        let pokemon = data.get(Pokemon.self, "pokemon")

        expect(pokemon.id) == "1234"
        expect(pokemon.name) == "Bulbasaur"

        let pokemon2 = data.get(Pokemon?.self, "pokemon")
        expect(pokemon2) == pokemon
    }

    func testReadNilObject() throws {
        var data = SelectorData()
        data.set("pokemon", object: nil)

        expect(data.get(Pokemon?.self, "pokemon")).to(beNil())
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
        assertSnapshot(matching: pokemons, as: .dump)

        let pokemons2 = data.get([Pokemon?]?.self, "pokemons")
        expect(pokemons2) == pokemons

        data.set("pokemons", objects: [pokemonData, pokemonData2])

        let pokemons3 = data.get([Pokemon].self, "pokemons")
        assertSnapshot(matching: pokemons3, as: .dump)

        let pokemons4 = data.get([Pokemon]?.self, "pokemons")
        expect(pokemons4) == pokemons3
    }

    func testAssignAndReadFragmentPointer() throws {
        var data = SelectorData()
        data.set(fragment: "PokemonListRow_pokemon",
                 variables: ["a": "b"],
                 dataID: "record_123",
                 owner: PokemonListQuery.createDescriptor(variables: ["a": "b"]).request)

        let pointer = data.get(fragment: "PokemonListRow_pokemon")
        assertSnapshot(matching: pointer, as: .dump)
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
        expect(pokemon.get(String.self, "id")) == "1234"
    }
}
