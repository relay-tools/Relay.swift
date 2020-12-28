// Auto-generated by relay-compiler. Do not edit.

import Relay

public struct PokemonDetailQuery {
    public var variables: Variables

    public init(variables: Variables) {
        self.variables = variables
    }

    public static var node: ConcreteRequest {
        ConcreteRequest(
            fragment: ReaderFragment(
                name: "PokemonDetailQuery",
                type: "Query",
                selections: [
                    .field(ReaderLinkedField(
                        name: "pokemon",
                        args: [
                            VariableArgument(name: "id", variableName: "id")
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
                            ))
                        ]
                    ))
                ]
            ),
            operation: NormalizationOperation(
                name: "PokemonDetailQuery",
                selections: [
                    .field(NormalizationLinkedField(
                        name: "pokemon",
                        args: [
                            VariableArgument(name: "id", variableName: "id")
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
                                    ))
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
                                    ))
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
                            ))
                        ]
                    ))
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
}

extension PokemonDetailQuery {
    public struct Variables: VariableDataConvertible {
        public var id: String?

        public init(id: String? = nil) {
            self.id = id
        }

        public var variableData: VariableData {
            [
                "id": id
            ]
        }
    }

    public init(id: String? = nil) {
        self.init(variables: .init(id: id))
    }
}

#if canImport(RelaySwiftUI)
import RelaySwiftUI

extension RelaySwiftUI.Query.WrappedValue where O == PokemonDetailQuery {
    public func get(id: String? = nil, fetchKey: Any? = nil) -> RelaySwiftUI.Query<PokemonDetailQuery>.Result {
        self.get(.init(id: id), fetchKey: fetchKey)
    }
}
#endif

#if canImport(RelaySwiftUI)
import RelaySwiftUI

extension RelaySwiftUI.RefetchableFragment.Wrapper where F.Operation == PokemonDetailQuery {
    public func refetch(id: String? = nil) {
        self.refetch(.init(id: id))
    }
}
#endif

extension PokemonDetailQuery {
    public struct Data: Decodable {
        public var pokemon: Pokemon_pokemon?

        public struct Pokemon_pokemon: Decodable, Identifiable, PokemonDetailInfoSection_pokemon_Key, PokemonDetailTypesSection_pokemon_Key {
            public var id: String
            public var fragment_PokemonDetailInfoSection_pokemon: FragmentPointer
            public var fragment_PokemonDetailTypesSection_pokemon: FragmentPointer
        }
    }
}

extension PokemonDetailQuery: Relay.Operation {}