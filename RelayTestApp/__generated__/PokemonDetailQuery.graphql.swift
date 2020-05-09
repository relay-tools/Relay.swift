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
                            .fragmentSpread(ReaderFragmentSpread(
                                name: "PokemonDetailTypesSection_pokemon"
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
                                    .field(NormalizationScalarField(
                                        name: "maximum"
                                    )),
                                ]
                            )),
                            .field(NormalizationScalarField(
                                name: "types"
                            )),
                            .field(NormalizationScalarField(
                                name: "resistant"
                            )),
                            .field(NormalizationScalarField(
                                name: "weaknesses"
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
    ...PokemonDetailTypesSection_pokemon
  }
}

fragment PokemonDetailInfoSection_pokemon on Pokemon {
  name
  number
  classification
  weight {
    minimum
    maximum
  }
  height {
    minimum
    maximum
  }
}

fragment PokemonDetailTypesSection_pokemon on Pokemon {
  types
  resistant
  weaknesses
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
        var pokemon: Pokemon_pokemon?

        init(from data: SelectorData) {
            pokemon = data.get(Pokemon_pokemon?.self, "pokemon")
        }

        struct Pokemon_pokemon: Readable, PokemonDetailInfoSection_pokemon_Key, PokemonDetailTypesSection_pokemon_Key {
            var id: String
            var fragment_PokemonDetailInfoSection_pokemon: FragmentPointer
            var fragment_PokemonDetailTypesSection_pokemon: FragmentPointer

            init(from data: SelectorData) {
                id = data.get(String.self, "id")
                fragment_PokemonDetailInfoSection_pokemon = data.get(fragment: "PokemonDetailInfoSection_pokemon")
                fragment_PokemonDetailTypesSection_pokemon = data.get(fragment: "PokemonDetailTypesSection_pokemon")
            }

        }
    }
}
