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
                    name: "title"
                )),
            ]
        )
    }

    func getFragmentPointer(_ key: MoviesListRow_film_Key) -> FragmentPointer {
        return key.fragment_MoviesListRow_film
    }

    struct Data: Readable {
        var id: String
        var title: String?

        init(from data: SelectorData) {
            id = data.get(String.self, "id")
            title = data.get(String?.self, "title")
        }

    }
}

protocol MoviesListRow_film_Key {
    var fragment_MoviesListRow_film: FragmentPointer { get }
}

