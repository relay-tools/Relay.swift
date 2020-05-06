//
//  ResponseNormalizerTests.swift
//  RelayTests
//
//  Created by Matt Moriarity on 5/4/20.
//  Copyright © 2020 Matt Moriarity. All rights reserved.
//

import XCTest
@testable import Relay

struct PokemonListQuery: Relay.Operation {
    var node: ConcreteRequest {
        ConcreteRequest(
            fragment: ReaderFragment(
                name: "PokemonListQuery",
                selections: [
                    .field(ReaderLinkedField(
                        name: "pokemons",
                        args: [LiteralArgument(name: "first", value: 50)],
                        concreteType: "Pokemon",
                        plural: true,
                        selections: [
                            .field(ReaderScalarField(name: "__typename")),
                            .field(ReaderScalarField(name: "id")),
                            .fragmentSpread(ReaderFragmentSpread(name: "PokemonListRow_pokemon"))]))]),
            operation: NormalizationOperation(
                name: "PokemonListQuery",
                argumentDefinitions: [],
                selections: [
                    .field(NormalizationLinkedField(
                        name: "pokemons",
                        args: [
                            LiteralArgument(name: "first", value: 50)],
                        concreteType: "Pokemon",
                        plural: true,
                        selections: [
                            .field(NormalizationScalarField(name: "id")),
                            .field(NormalizationScalarField(name: "name")),
                            .field(NormalizationScalarField(name: "number")),
                            .field(NormalizationScalarField(name: "classification"))]))]),
            params: RequestParameters(
                name: "PokemonListQuery",
                operationKind: .query,
                text: """
query PokemonListQuery {
    pokemons(first: 50) {
        __typename
        id
        ...PokemonListRow_pokemon
    }
}

fragment PokemonListRow_pokemon on Pokemon {
    name
    number
    classification
}
"""))
    }

    struct Variables: Encodable {
    }

    struct Response: Decodable {
        var pokemons: [Pokemon]

        struct Pokemon: Decodable {
            var id: String
            var name: String?
            var number: String?
            var classification: String?
        }
    }
}


class ResponseNormalizerTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testNormalizeValidPayload() throws {
        let payload = """
{
  "pokemons": [
    {
      "id": "UG9rZW1vbjowMDE=",
      "number": "001",
      "name": "Bulbasaur",
      "classification": "Seed Pokémon"
    },
    {
      "id": "UG9rZW1vbjowMDI=",
      "number": "002",
      "name": "Ivysaur",
      "classification": "Seed Pokémon"
    },
    {
      "id": "UG9rZW1vbjowMDM=",
      "number": "003",
      "name": "Venusaur",
      "classification": "Seed Pokémon"
    }
  ]
}
"""
        let parsedPayload = try JSONSerialization.jsonObject(with: payload.data(using: .utf8)!, options: []) as! [String: Any]

        var recordSource: RecordSource = DefaultRecordSource()
        recordSource[.rootID] = .root

        let op = PokemonListQuery().createDescriptor(variables: .init())
        let response = ResponseNormalizer.normalize(
            recordSource: recordSource,
            selector: op.root,
            data: parsedPayload,
            request: op.request)
        recordSource = response.source

        XCTAssertEqual(
            recordSource[.rootID],
            Record(
                dataID: .rootID,
                typename: "__Root",
                linkedPluralRecordIDs: [
                    "pokemons(first:50)": [
                        DataID("UG9rZW1vbjowMDE="),
                        DataID("UG9rZW1vbjowMDI="),
                        DataID("UG9rZW1vbjowMDM="),
                    ]
            ]))
        XCTAssertEqual(
            recordSource[DataID("UG9rZW1vbjowMDE=")],
            Record(
                dataID: DataID("UG9rZW1vbjowMDE="),
                typename: "Pokemon",
                values: [
                    "id": "UG9rZW1vbjowMDE=",
                    "number": "001",
                    "name": "Bulbasaur",
                    "classification": "Seed Pokémon"
            ]))
        XCTAssertEqual(
            recordSource[DataID("UG9rZW1vbjowMDI=")],
            Record(
                dataID: DataID("UG9rZW1vbjowMDI="),
                typename: "Pokemon",
                values: [
                    "id": "UG9rZW1vbjowMDI=",
                    "number": "002",
                    "name": "Ivysaur",
                    "classification": "Seed Pokémon"
            ]))
        XCTAssertEqual(
            recordSource[DataID("UG9rZW1vbjowMDM=")],
            Record(
                dataID: DataID("UG9rZW1vbjowMDM="),
                typename: "Pokemon",
                values: [
                    "id": "UG9rZW1vbjowMDM=",
                    "number": "003",
                    "name": "Venusaur",
                    "classification": "Seed Pokémon"
            ]))
    }

}
