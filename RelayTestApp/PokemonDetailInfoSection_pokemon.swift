import Relay

struct PokemonDetailInfoSection_pokemon: Fragment {
    var node: ReaderFragment {
        ReaderFragment(
            name: "PokemonDetailInfoSection_pokemon",
            selections: [
                .field(ReaderScalarField(name: "name")),
                .field(ReaderScalarField(name: "number")),
                .field(ReaderScalarField(name: "classification"))])
    }

    func getFragmentPointer(_ key: PokemonDetailInfoSection_pokemon_Key) -> FragmentPointer {
        return key.fragment_PokemonDetailInfoSection_pokemon
    }

    struct Variables: Relay.Variables {
        var asDictionary: [String : Any] { [:] }
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

protocol PokemonDetailInfoSection_pokemon_Key {
    var fragment_PokemonDetailInfoSection_pokemon: FragmentPointer { get }
}
