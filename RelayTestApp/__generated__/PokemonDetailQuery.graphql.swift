import Relay

struct PokemonDetailQuery: Operation {
    var node: ConcreteRequest {
        return ConcreteRequest(
            fragment: ReaderFragment(
                name: "PokemonDetailQuery",
                selections: [
                    .field(ReaderLinkedField(
                        name: "pokemon",
                        args: [
                            VariableArgument(name: "id", variableName: "id"),
                        ],
                        concreteType: "Pokemon",
                        plural: false,
                        selections: [
                            .field(ReaderScalarField(
                                name: "id"
                            )),
                            .fragmentSpread(ReaderFragmentSpread(
                                name: "PokemonDetailInfoSection_pokemon"
                            )),
                        ]
                    )),
                ]
            ),
            operation: NormalizationOperation(
                name: "PokemonDetailQuery",
                selections: [
                    .field(NormalizationLinkedField(
                        name: "pokemon",
                        args: [
                            VariableArgument(name: "id", variableName: "id"),
                        ],
                        concreteType: "Pokemon",
                        plural: false,
                        selections: [
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
                        ]
                    )),
                ]
            ),
            params: RequestParameters(
                name: "PokemonDetailQuery",
                operationKind: .query,
                text: """
query PokemonDetailQuery(
  $id: String
) {
  pokemon(id: $id) {
    id
    ...PokemonDetailInfoSection_pokemon
  }
}

fragment PokemonDetailInfoSection_pokemon on Pokemon {
  name
  number
  classification
}
"""
            )
        )
    }

    struct Variables: Relay.Variables {
        var id: String?

        var asDictionary: [String: Any] {
            [
                "id": id as Any,
            ]
        }
    }

    struct Data: Readable {
        var pokemon: Pokemon?

        init(from data: SelectorData) {
            pokemon = data.get(Pokemon?.self, "pokemon")
        }

        struct Pokemon: Readable, PokemonDetailInfoSection_pokemon_Key {
            var id: String
            var fragment_PokemonDetailInfoSection_pokemon: FragmentPointer

            init(from data: SelectorData) {
                id = data.get(String.self, "id")
                fragment_PokemonDetailInfoSection_pokemon = data.get(fragment: "PokemonDetailInfoSection_pokemon")
            }

        }
    }
}
