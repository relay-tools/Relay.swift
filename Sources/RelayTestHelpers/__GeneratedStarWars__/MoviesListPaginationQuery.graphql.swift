// Auto-generated by relay-compiler. Do not edit.

import Relay

public struct MoviesListPaginationQuery {
    public var variables: Variables

    public init(variables: Variables) {
        self.variables = variables
    }

    public static var node: ConcreteRequest {
        ConcreteRequest(
            fragment: ReaderFragment(
                name: "MoviesListPaginationQuery",
                type: "Root",
                selections: [
                    .fragmentSpread(ReaderFragmentSpread(
                        name: "MoviesList_films",
                        args: [
                            VariableArgument(name: "count", variableName: "count"),
                            VariableArgument(name: "cursor", variableName: "cursor")
                        ]
                    ))
                ]
            ),
            operation: NormalizationOperation(
                name: "MoviesListPaginationQuery",
                selections: [
                    .field(NormalizationLinkedField(
                        name: "allFilms",
                        args: [
                            VariableArgument(name: "after", variableName: "cursor"),
                            VariableArgument(name: "first", variableName: "count")
                        ],
                        concreteType: "FilmsConnection",
                        plural: false,
                        selections: [
                            .field(NormalizationLinkedField(
                                name: "edges",
                                concreteType: "FilmsEdge",
                                plural: true,
                                selections: [
                                    .field(NormalizationLinkedField(
                                        name: "node",
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
                                            )),
                                            .field(NormalizationScalarField(
                                                name: "__typename"
                                            ))
                                        ]
                                    )),
                                    .field(NormalizationScalarField(
                                        name: "cursor"
                                    ))
                                ]
                            )),
                            .field(NormalizationLinkedField(
                                name: "pageInfo",
                                concreteType: "PageInfo",
                                plural: false,
                                selections: [
                                    .field(NormalizationScalarField(
                                        name: "endCursor"
                                    )),
                                    .field(NormalizationScalarField(
                                        name: "hasNextPage"
                                    ))
                                ]
                            )),
                            .clientExtension(NormalizationClientExtension(
                                selections: [
                                    .field(NormalizationScalarField(
                                        name: "__id"
                                    ))
                                ]
                            ))
                        ]
                    )),
                    .handle(NormalizationHandle(
                        kind: .linked,
                        name: "allFilms",
                        args: [
                            VariableArgument(name: "after", variableName: "cursor"),
                            VariableArgument(name: "first", variableName: "count")
                        ],
                        handle: "connection",
                        key: "MoviesList_allFilms"
                    ))
                ]
            ),
            params: RequestParameters(
                name: "MoviesListPaginationQuery",
                operationKind: .query,
                text: """
query MoviesListPaginationQuery(
  $count: Int = 3
  $cursor: String
) {
  ...MoviesList_films_1G22uz
}

fragment MoviesListRow_film on Film {
  id
  episodeID
  title
  director
  releaseDate
}

fragment MoviesList_films_1G22uz on Root {
  allFilms(first: $count, after: $cursor) {
    edges {
      node {
        id
        ...MoviesListRow_film
        __typename
      }
      cursor
    }
    pageInfo {
      endCursor
      hasNextPage
    }
  }
}
"""
            )
        )
    }
}

extension MoviesListPaginationQuery {
    public struct Variables: VariableDataConvertible {
        public var count: Int?
        public var cursor: String?

        public init(count: Int? = nil, cursor: String? = nil) {
            self.count = count
            self.cursor = cursor
        }

        public var variableData: VariableData {
            [
                "count": count,
                "cursor": cursor
            ]
        }
    }

    public init(count: Int? = nil, cursor: String? = nil) {
        self.init(variables: .init(count: count, cursor: cursor))
    }
}

#if canImport(RelaySwiftUI)
import RelaySwiftUI

extension RelaySwiftUI.Query.WrappedValue where O == MoviesListPaginationQuery {
    public func get(count: Int? = nil, cursor: String? = nil, fetchKey: Any? = nil) -> RelaySwiftUI.Query<MoviesListPaginationQuery>.Result {
        self.get(.init(count: count, cursor: cursor), fetchKey: fetchKey)
    }
}
#endif

#if canImport(RelaySwiftUI)
import RelaySwiftUI

extension RelaySwiftUI.RefetchableFragment.Wrapper where F.Operation == MoviesListPaginationQuery {
    public func refetch(count: Int? = nil, cursor: String? = nil) async {
        await self.refetch(.init(count: count, cursor: cursor))
    }
}
#endif

extension MoviesListPaginationQuery {
    public struct Data: Decodable, MoviesList_films_Key {
        public var fragment_MoviesList_films: FragmentPointer
    }
}

extension MoviesListPaginationQuery: Relay.Operation {}