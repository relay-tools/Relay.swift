import XCTest
import SnapshotTesting
import Nimble
@testable import Relay

fileprivate struct Data: Decodable {
    var pokemon: Pokemon?
}

fileprivate struct Data2: Decodable {
    var pokemons: [Pokemon?]
    var pokemons2: [Pokemon?]?
    var pokemons3: [Pokemon]
    var pokemons4: [Pokemon]?
}

fileprivate struct Data3: Decodable {
    var fragment_PokemonListRow_pokemon: FragmentPointer
}

fileprivate struct Pokemon: Decodable, Hashable {
    var id: String
    var name: String?
}

class SelectorDataTests: XCTestCase {
    func testEmptyData() throws {
        let data = SelectorData()
        expect(data.get(String?.self, "someField")).to(beNil())
        expect(data.get(SelectorData?.self, "someField")).to(beNil())
        expect(data.get([SelectorData?]?.self, "someField")).to(beNil())
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

    func testAssignAndReadObject() throws {
        var pokemonData = SelectorData()
        pokemonData.set("id", scalar: "1234")
        pokemonData.set("name", scalar: "Bulbasaur")

        var data = SelectorData()
        data.set("pokemon", object: pokemonData)

        let readData = try SelectorDataDecoder().decode(Data.self, from: data)

        expect(readData.pokemon?.id) == "1234"
        expect(readData.pokemon?.name) == "Bulbasaur"
    }

    func testReadNilObject() throws {
        var data = SelectorData()
        data.set("pokemon", object: nil)

        let readData = try SelectorDataDecoder().decode(Data.self, from: data)
        expect(readData.pokemon).to(beNil())
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
        data.set("pokemons2", objects: [pokemonData, nil, pokemonData2])
        data.set("pokemons3", objects: [pokemonData, pokemonData2])
        data.set("pokemons4", objects: [pokemonData, pokemonData2])

        let readData = try SelectorDataDecoder().decode(Data2.self, from: data)
        assertSnapshot(matching: readData.pokemons, as: .dump)
        expect(readData.pokemons2) == readData.pokemons
        assertSnapshot(matching: readData.pokemons3, as: .dump)
        expect(readData.pokemons4) == readData.pokemons3
    }

    func testAssignAndReadFragmentPointer() throws {
        var data = SelectorData()
        data.set(fragment: "PokemonListRow_pokemon",
                 variables: ["a": "b"],
                 dataID: "record_123",
                 owner: PokemonListQuery.createDescriptor(variables: ["a": "b"]).request)

        let readData = try SelectorDataDecoder().decode(Data3.self, from: data)
        assertSnapshot(matching: readData.fragment_PokemonListRow_pokemon, as: .dump)
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
