import Relay

struct PokemonListRow_pokemon: Fragment {
    var node: ReaderFragment {
        return ReaderFragment(
            name: "PokemonListRow_pokemon",
            selections: [
                .field(ReaderScalarField(
                    name: "name"
                )),
                .field(ReaderScalarField(
                    name: "number"
                )),
                .field(ReaderScalarField(
                    name: "classification"
                )),
            ]
        )
    }

    func getFragmentPointer(_ key: PokemonListRow_pokemon_Key) -> FragmentPointer {
        return key.fragment_PokemonListRow_pokemon
    }

    struct Data: Readable {
        var name: String?
        var number: String?
        var classification: String?

        init(from data: SelectorData) {
            name = data.get(String?.self, "name")
            number = data.get(String?.self, "number")
            classification = data.get(String?.self, "classification")
        }

    }
}

protocol PokemonListRow_pokemon_Key {
    var fragment_PokemonListRow_pokemon: FragmentPointer { get }
}

