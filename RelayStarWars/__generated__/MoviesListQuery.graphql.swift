import Relay

struct MoviesListQuery: Operation {
    var node: ConcreteRequest {
        return ConcreteRequest(
            fragment: ReaderFragment(
                name: "MoviesListQuery",
                selections: [
                    .field(ReaderLinkedField(
                        name: "allFilms",
                        args: [
                            LiteralArgument(name: "first", value: 10),
                        ],
                        concreteType: "FilmsConnection",
                        plural: false,
                        selections: [
                            .field(ReaderLinkedField(
                                name: "edges",
                                concreteType: "FilmsEdge",
                                plural: true,
                                selections: [
                                    .field(ReaderLinkedField(
                                        name: "node",
                                        concreteType: "Film",
                                        plural: false,
                                        selections: [
                                            .field(ReaderScalarField(
                                                name: "id"
                                            )),
                                            .fragmentSpread(ReaderFragmentSpread(
                                                name: "MoviesListRow_film"
                                            )),
                                        ]
                                    )),
                                ]
                            )),
                        ]
                    )),
                ]
            ),
            operation: NormalizationOperation(
                name: "MoviesListQuery",
                selections: [
                    .field(NormalizationLinkedField(
                        name: "allFilms",
                        args: [
                            LiteralArgument(name: "first", value: 10),
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
                                                name: "title"
                                            )),
                                        ]
                                    )),
                                ]
                            )),
                        ]
                    )),
                ]
            ),
            params: RequestParameters(
                name: "MoviesListQuery",
                operationKind: .query,
                text: """
query MoviesListQuery {
  allFilms(first: 10) {
    edges {
      node {
        id
        ...MoviesListRow_film
      }
    }
  }
}

fragment MoviesListRow_film on Film {
  id
  title
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
        var allFilms: FilmsConnection_allFilms?

        init(from data: SelectorData) {
            allFilms = data.get(FilmsConnection_allFilms?.self, "allFilms")
        }

        struct FilmsConnection_allFilms: Readable {
            var edges: [FilmsEdge_edges?]?

            init(from data: SelectorData) {
                edges = data.get([FilmsEdge_edges?]?.self, "edges")
            }

            struct FilmsEdge_edges: Readable {
                var node: Film_node?

                init(from data: SelectorData) {
                    node = data.get(Film_node?.self, "node")
                }

                struct Film_node: Readable, MoviesListRow_film_Key {
                    var id: String
                    var fragment_MoviesListRow_film: FragmentPointer

                    init(from data: SelectorData) {
                        id = data.get(String.self, "id")
                        fragment_MoviesListRow_film = data.get(fragment: "MoviesListRow_film")
                    }

                }
            }
        }
    }
}
