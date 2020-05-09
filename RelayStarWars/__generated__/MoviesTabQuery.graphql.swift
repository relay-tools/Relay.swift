import Relay

struct MoviesTabQuery: Operation {
    var node: ConcreteRequest {
        return ConcreteRequest(
            fragment: ReaderFragment(
                name: "MoviesTabQuery",
                selections: [
                    .fragmentSpread(ReaderFragmentSpread(
                        name: "MoviesList_films"
                    )),
                ]
            ),
            operation: NormalizationOperation(
                name: "MoviesTabQuery",
                selections: [
                    .field(NormalizationLinkedField(
                        name: "allFilms",
                        args: [
                            LiteralArgument(name: "first", value: 3),
                        ],
                        storageKey: "allFilms(first:3)",
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
                                                name: "title"
                                            )),
                                            .field(NormalizationScalarField(
                                                name: "__typename"
                                            )),
                                        ]
                                    )),
                                    .field(NormalizationScalarField(
                                        name: "cursor"
                                    )),
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
                                    )),
                                ]
                            )),
                        ]
                    )),
                    .handle(NormalizationHandle(
                        kind: .linked,
                        name: "allFilms",
                        args: [
                            LiteralArgument(name: "first", value: 3),
                        ],
                        handle: "connection",
                        key: "MoviesList_allFilms"
                    )),
                ]
            ),
            params: RequestParameters(
                name: "MoviesTabQuery",
                operationKind: .query,
                text: """
query MoviesTabQuery {
  ...MoviesList_films
}

fragment MoviesListRow_film on Film {
  id
  title
}

fragment MoviesList_films on Root {
  allFilms(first: 3) {
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

    struct Variables: Relay.Variables {
        var asDictionary: [String: Any] {
            [:]
        }
    }

    struct Data: Readable, MoviesList_films_Key {
        var fragment_MoviesList_films: FragmentPointer

        init(from data: SelectorData) {
            fragment_MoviesList_films = data.get(fragment: "MoviesList_films")
        }

    }
}
