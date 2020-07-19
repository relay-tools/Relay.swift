// Auto-generated by relay-compiler. Do not edit.

import Relay

public struct MovieDetailQuery {
    public var variables: Variables

    public init(variables: Variables) {
        self.variables = variables
    }

    public static var node: ConcreteRequest {
        ConcreteRequest(
            fragment: ReaderFragment(
                name: "MovieDetailQuery",
                type: "Root",
                selections: [
                    .field(ReaderLinkedField(
                        name: "film",
                        args: [
                            VariableArgument(name: "id", variableName: "id")
                        ],
                        concreteType: "Film",
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
                name: "MovieDetailQuery",
                selections: [
                    .field(NormalizationLinkedField(
                        name: "film",
                        args: [
                            VariableArgument(name: "id", variableName: "id")
                        ],
                        concreteType: "Film",
                        plural: false,
                        selections: [
                            .field(NormalizationScalarField(
                                name: "id"
                            )),
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
            ),
            params: RequestParameters(
                name: "MovieDetailQuery",
                operationKind: .query,
                text: """
query MovieDetailQuery(
  $id: ID!
) {
  film(id: $id) {
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

extension MovieDetailQuery {
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

#if swift(>=5.3) && canImport(RelaySwiftUI)
import RelaySwiftUI

@available(iOS 14.0, macOS 10.16, tvOS 14.0, watchOS 7.0, *)extension RelaySwiftUI.QueryNext.WrappedValue where O == MovieDetailQuery {
    public func get(id: String, fetchKey: Any? = nil) -> RelaySwiftUI.QueryNext<MovieDetailQuery>.Result {
        self.get(.init(id: id), fetchKey: fetchKey)
    }
}
#endif
extension MovieDetailQuery {
    public struct Data: Decodable {
        public var film: Film_film?

        public struct Film_film: Decodable, MovieInfoSection_film_Key {
            public var fragment_MovieInfoSection_film: FragmentPointer
        }
    }
}
extension MovieDetailQuery: Relay.Operation {}