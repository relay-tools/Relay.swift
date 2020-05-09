import Relay

struct PokemonListQuery: Operation {
    var node: ConcreteRequest {
        return ConcreteRequest(
            fragment: ReaderFragment(
                name: "PokemonListQuery",
                selections: [
                    .field(ReaderLinkedField(
                        name: "pokemons",
                        args: [
                            LiteralArgument(name: "first", value: 50),
                        ],
                        concreteType: "Pokemon",
                        plural: true,
                        selections: [
                            .field(ReaderScalarField(
                                name: "__typename"
                            )),
                            .field(ReaderScalarField(
                                name: "id"
                            )),
                            .field(ReaderScalarField(
                                name: "name"
                            )),
                            .fragmentSpread(ReaderFragmentSpread(
                                name: "PokemonListRow_pokemon"
                            )),
                        ]
                    )),
                ]
            ),
            operation: NormalizationOperation(
                name: "PokemonListQuery",
                selections: [
                    .field(NormalizationLinkedField(
                        name: "pokemons",
                        args: [
                            LiteralArgument(name: "first", value: 50),
                        ],
                        concreteType: "Pokemon",
                        plural: true,
                        selections: [
                            .field(NormalizationScalarField(
                                name: "__typename"
                            )),
                            .field(NormalizationScalarField(
                                name: "id"
                            )),
                            .field(NormalizationScalarField(
                                name: "name"
                            )),
                            .field(NormalizationScalarField(
                                name: "number"
                            )),
                            .field(NormalizationScalarField(
                                name: "classification"
                            )),
                            .field(NormalizationLinkedField(
                                name: "weight",
                                concreteType: "PokemonDimension",
                                plural: false,
                                selections: [
                                    .field(NormalizationScalarField(
                                        name: "minimum"
                                    )),
                                    .field(NormalizationScalarField(
                                        name: "maximum"
                                    )),
                                ]
                            )),
                            .field(NormalizationLinkedField(
                                name: "height",
                                concreteType: "PokemonDimension",
                                plural: false,
                                selections: [
                                    .field(NormalizationScalarField(
                                        name: "minimum"
                                    )),
                                ]
                            )),
                        ]
                    )),
                ]
            ),
            params: RequestParameters(
                name: "PokemonListQuery",
                operationKind: .query,
                text: """
query PokemonListQuery {
  pokemons(first: 50) {
    __typename
    id
    name
    ...PokemonListRow_pokemon
  }
}

fragment PokemonListRow_pokemon on Pokemon {
  name
  number
  classification
  weight {
    minimum
    maximum
  }
  height {
    minimum
  }
}
"""
            )
        )
    }

    struct Variables: Relay.Variables {
        var asDictionary: [String: Any] {
            [:]
        }
    }

    struct Data: Readable {
        var pokemons: [Pokemon_pokemons?]?

        init(from data: SelectorData) {
            pokemons = data.get([Pokemon_pokemons?]?.self, "pokemons")
        }

        struct Pokemon_pokemons: Readable, PokemonListRow_pokemon_Key {
            var __typename: String
            var id: String
            var name: String?
            var fragment_PokemonListRow_pokemon: FragmentPointer

            init(from data: SelectorData) {
                __typename = data.get(String.self, "__typename")
                id = data.get(String.self, "id")
                name = data.get(String?.self, "name")
                fragment_PokemonListRow_pokemon = data.get(fragment: "PokemonListRow_pokemon")
            }

        }
    }
}
