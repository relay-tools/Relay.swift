import Relay

struct PokemonDetailTypesSection_pokemon: Fragment {
    var node: ReaderFragment {
        return ReaderFragment(
            name: "PokemonDetailTypesSection_pokemon",
            selections: [
                .field(ReaderScalarField(
                    name: "types"
                )),
                .field(ReaderScalarField(
                    name: "resistant"
                )),
                .field(ReaderScalarField(
                    name: "weaknesses"
                )),
            ]
        )
    }

    func getFragmentPointer(_ key: PokemonDetailTypesSection_pokemon_Key) -> FragmentPointer {
        return key.fragment_PokemonDetailTypesSection_pokemon
    }

    struct Data: Readable {
        var types: [String?]?
        var resistant: [String?]?
        var weaknesses: [String?]?

        init(from data: SelectorData) {
            types = data.get([String?]?.self, "types")
            resistant = data.get([String?]?.self, "resistant")
            weaknesses = data.get([String?]?.self, "weaknesses")
        }

    }
}

protocol PokemonDetailTypesSection_pokemon_Key {
    var fragment_PokemonDetailTypesSection_pokemon: FragmentPointer { get }
}

