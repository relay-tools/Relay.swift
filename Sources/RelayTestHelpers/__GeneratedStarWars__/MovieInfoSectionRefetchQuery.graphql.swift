// Auto-generated by relay-compiler. Do not edit.

import Relay

public struct MovieInfoSectionRefetchQuery {
    public var variables: Variables

    public init(variables: Variables) {
        self.variables = variables
    }

    public static var node: ConcreteRequest {
        ConcreteRequest(
            fragment: ReaderFragment(
                name: "MovieInfoSectionRefetchQuery",
                type: "Root",
                selections: [
                    .field(ReaderLinkedField(
                        name: "node",
                        args: [
                            VariableArgument(name: "id", variableName: "id")
                        ],
                        plural: false,
                        selections: [
                            .fragmentSpread(ReaderFragmentSpread(
                                name: "MovieInfoSection_film"
                            ))
                        ]
                    ))
                ]
            ),
            operation: NormalizationOperation(
                name: "MovieInfoSectionRefetchQuery",
                selections: [
                    .field(NormalizationLinkedField(
                        name: "node",
                        args: [
                            VariableArgument(name: "id", variableName: "id")
                        ],
                        plural: false,
                        selections: [
                            .field(NormalizationScalarField(
                                name: "__typename"
                            )),
                            .field(NormalizationScalarField(
                                name: "id"
                            )),
                            .inlineFragment(NormalizationInlineFragment(
                                type: "Film",
                                selections: [
                                    .field(NormalizationScalarField(
                                        name: "episodeID"
                                    )),
                                    .field(NormalizationScalarField(
                                        name: "title"
                                    )),
                                    .field(NormalizationScalarField(
                                        name: "director"
                                    )),
                                    .field(NormalizationScalarField(
                                        name: "releaseDate"
                                    ))
                                ]
                            ))
                        ]
                    ))
                ]
            ),
            params: RequestParameters(
                name: "MovieInfoSectionRefetchQuery",
                operationKind: .query,
                text: """
query MovieInfoSectionRefetchQuery(
  $id: ID!
) {
  node(id: $id) {
    __typename
    ...MovieInfoSection_film
    id
  }
}

fragment MovieInfoSection_film on Film {
  id
  episodeID
  title
  director
  releaseDate
}
"""
            )
        )
    }
}

extension MovieInfoSectionRefetchQuery {
    public struct Variables: VariableDataConvertible {
        public var id: String

        public init(id: String) {
            self.id = id
        }

        public var variableData: VariableData {
            [
                "id": id
            ]
        }
    }

    public init(id: String) {
        self.init(variables: .init(id: id))
    }
}

#if canImport(RelaySwiftUI)
import RelaySwiftUI

extension RelaySwiftUI.Query.WrappedValue where O == MovieInfoSectionRefetchQuery {
    public func get(id: String, fetchKey: Any? = nil) -> RelaySwiftUI.Query<MovieInfoSectionRefetchQuery>.Result {
        self.get(.init(id: id), fetchKey: fetchKey)
    }
}
#endif

#if canImport(RelaySwiftUI)
import RelaySwiftUI

extension RelaySwiftUI.RefetchableFragment.Wrapper where F.Operation == MovieInfoSectionRefetchQuery {
    public func refetch(id: String) {
        self.refetch(.init(id: id))
    }
}
#endif

extension MovieInfoSectionRefetchQuery {
    public struct Data: Decodable {
        public var node: Node_node?

        public struct Node_node: Decodable, MovieInfoSection_film_Key {
            public var fragment_MovieInfoSection_film: FragmentPointer
        }
    }
}

extension MovieInfoSectionRefetchQuery: Relay.Operation {}