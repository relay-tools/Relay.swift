//
//  ReaderTests.swift
//  RelayTests
//
//  Created by Matt Moriarity on 5/6/20.
//  Copyright © 2020 Matt Moriarity. All rights reserved.
//

import XCTest
@testable import Relay

class ReaderTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testReaderFromRoot() throws {
        let operation = PokemonListQuery().createDescriptor()
        let selector = operation.fragment

        var source = DefaultRecordSource()
        source[.rootID] = Record(dataID: .rootID, typename: "__Root", linkedPluralRecordIDs: [
            "pokemons(first:50)":[
                "UG9rZW1vbjowMDE=",
                "UG9rZW1vbjowMDI=",
                "UG9rZW1vbjowMDM=",
            ]
        ])
        source["UG9rZW1vbjowMDE="] = Record(
            dataID: DataID("UG9rZW1vbjowMDE="),
            typename: "Pokemon",
            values: [
                "id": "UG9rZW1vbjowMDE=",
                "__typename": "Pokemon",
                "number": "001",
                "name": "Bulbasaur",
                "classification": "Seed Pokémon"
        ])
        source["UG9rZW1vbjowMDI="] = Record(
            dataID: DataID("UG9rZW1vbjowMDI="),
            typename: "Pokemon",
            values: [
                "id": "UG9rZW1vbjowMDI=",
                "__typename": "Pokemon",
                "number": "002",
                "name": "Ivysaur",
                "classification": "Seed Pokémon"
        ])
        source["UG9rZW1vbjowMDM="] = Record(
            dataID: DataID("UG9rZW1vbjowMDM="),
            typename: "Pokemon",
            values: [
                "id": "UG9rZW1vbjowMDM=",
                "__typename": "Pokemon",
                "number": "003",
                "name": "Venusaur",
                "classification": "Seed Pokémon"
        ])

        let snapshot = Reader.read(PokemonListQuery.Data.self, source: source, selector: selector)

        XCTAssertNotNil(snapshot.data)
        XCTAssertEqual(snapshot.data!.pokemons!.count, 3)
        XCTAssertEqual(snapshot.data!.pokemons!.map { $0!.id }, [
            "UG9rZW1vbjowMDE=",
            "UG9rZW1vbjowMDI=",
            "UG9rZW1vbjowMDM=",
        ])
        XCTAssert(snapshot.data!.pokemons!.allSatisfy { $0!.__typename == "Pokemon" })
    }

    func testReaderFromFragmentPointer() {
        let operation = PokemonListQuery().createDescriptor()

        var source = DefaultRecordSource()
        source[.rootID] = Record(dataID: .rootID, typename: "__Root", linkedPluralRecordIDs: [
            "pokemons(first:50)":[
                "UG9rZW1vbjowMDE=",
                "UG9rZW1vbjowMDI=",
                "UG9rZW1vbjowMDM=",
            ]
        ])
        source["UG9rZW1vbjowMDE="] = Record(
            dataID: DataID("UG9rZW1vbjowMDE="),
            typename: "Pokemon",
            values: [
                "id": "UG9rZW1vbjowMDE=",
                "__typename": "Pokemon",
                "number": "001",
                "name": "Bulbasaur",
                "classification": "Seed Pokémon"
        ])
        source["UG9rZW1vbjowMDI="] = Record(
            dataID: DataID("UG9rZW1vbjowMDI="),
            typename: "Pokemon",
            values: [
                "id": "UG9rZW1vbjowMDI=",
                "__typename": "Pokemon",
                "number": "002",
                "name": "Ivysaur",
                "classification": "Seed Pokémon"
        ])
        source["UG9rZW1vbjowMDM="] = Record(
            dataID: DataID("UG9rZW1vbjowMDM="),
            typename: "Pokemon",
            values: [
                "id": "UG9rZW1vbjowMDM=",
                "__typename": "Pokemon",
                "number": "003",
                "name": "Venusaur",
                "classification": "Seed Pokémon"
        ])

        let opSnapshot = Reader.read(PokemonListQuery.Data.self, source: source, selector: operation.fragment)
        let pointer = opSnapshot.data!.pokemons![1]!.fragment_PokemonListRow_pokemon

        let selector = SingularReaderSelector(fragment: PokemonListRow_pokemon.node, pointer: pointer)
        let snapshot = Reader.read(PokemonListRow_pokemon.Data.self, source: source, selector: selector)

        XCTAssertNotNil(snapshot.data)
        XCTAssertEqual(snapshot.data!.number, "002")
        XCTAssertEqual(snapshot.data!.name, "Ivysaur")
    }

}
