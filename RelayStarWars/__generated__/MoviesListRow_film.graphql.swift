import Relay

struct MoviesListRow_film: Fragment {
    var node: ReaderFragment {
        return ReaderFragment(
            name: "MoviesListRow_film",
            selections: [
                .field(ReaderScalarField(
                    name: "id"
                )),
                .field(ReaderScalarField(
                    name: "episodeID"
                )),
                .field(ReaderScalarField(
                    name: "title"
                )),
                .field(ReaderScalarField(
                    name: "director"
                )),
                .field(ReaderScalarField(
                    name: "releaseDate"
                )),
            ]
        )
    }

    func getFragmentPointer(_ key: MoviesListRow_film_Key) -> FragmentPointer {
        return key.fragment_MoviesListRow_film
    }

    struct Data: Readable {
        var id: String
        var episodeID: Int?
        var title: String?
        var director: String?
        var releaseDate: String?

        init(from data: SelectorData) {
            id = data.get(String.self, "id")
            episodeID = data.get(Int?.self, "episodeID")
            title = data.get(String?.self, "title")
            director = data.get(String?.self, "director")
            releaseDate = data.get(String?.self, "releaseDate")
        }

    }
}

protocol MoviesListRow_film_Key {
    var fragment_MoviesListRow_film: FragmentPointer { get }
}

