import Relay

struct MoviesList_films: Fragment {
    var node: ReaderFragment {
        return ReaderFragment(
            name: "MoviesList_films",
            selections: [
                .field(ReaderLinkedField(
                    name: "__MoviesList_allFilms_connection",
                    alias: "allFilms",
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
                                        .field(ReaderScalarField(
                                            name: "__typename"
                                        )),
                                        .fragmentSpread(ReaderFragmentSpread(
                                            name: "MoviesListRow_film"
                                        )),
                                    ]
                                )),
                                .field(ReaderScalarField(
                                    name: "cursor"
                                )),
                            ]
                        )),
                        .field(ReaderLinkedField(
                            name: "pageInfo",
                            concreteType: "PageInfo",
                            plural: false,
                            selections: [
                                .field(ReaderScalarField(
                                    name: "endCursor"
                                )),
                                .field(ReaderScalarField(
                                    name: "hasNextPage"
                                )),
                            ]
                        )),
                    ]
                )),
            ]
        )
    }

    func getFragmentPointer(_ key: MoviesList_films_Key) -> FragmentPointer {
        return key.fragment_MoviesList_films
    }

    struct Data: Readable {
        var allFilms: FilmsConnection_allFilms?

        init(from data: SelectorData) {
            allFilms = data.get(FilmsConnection_allFilms?.self, "allFilms")
        }

        struct FilmsConnection_allFilms: Readable {
            var edges: [FilmsEdge_edges?]?
            var pageInfo: PageInfo_pageInfo

            init(from data: SelectorData) {
                edges = data.get([FilmsEdge_edges?]?.self, "edges")
                pageInfo = data.get(PageInfo_pageInfo.self, "pageInfo")
            }

            struct FilmsEdge_edges: Readable {
                var node: Film_node?
                var cursor: String

                init(from data: SelectorData) {
                    node = data.get(Film_node?.self, "node")
                    cursor = data.get(String.self, "cursor")
                }

                struct Film_node: Readable, MoviesListRow_film_Key {
                    var id: String
                    var __typename: String
                    var fragment_MoviesListRow_film: FragmentPointer

                    init(from data: SelectorData) {
                        id = data.get(String.self, "id")
                        __typename = data.get(String.self, "__typename")
                        fragment_MoviesListRow_film = data.get(fragment: "MoviesListRow_film")
                    }

                }
            }
            struct PageInfo_pageInfo: Readable {
                var endCursor: String?
                var hasNextPage: Bool

                init(from data: SelectorData) {
                    endCursor = data.get(String?.self, "endCursor")
                    hasNextPage = data.get(Bool.self, "hasNextPage")
                }

            }
        }
    }
}

extension MoviesList_films: PaginationFragment {
    typealias Operation = MoviesListPaginationQuery

    var metadata: Metadata {
        RefetchMetadata(
            path: [],
            operation: .init(),
            connection: ConnectionMetadata(
                path: ["allFilms"],
                forward: ConnectionVariableConfig(count: "count", cursor: "cursor")))
    }
}

protocol MoviesList_films_Key {
    var fragment_MoviesList_films: FragmentPointer { get }
}

