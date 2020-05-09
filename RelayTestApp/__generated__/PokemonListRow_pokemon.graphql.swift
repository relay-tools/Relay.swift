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
                .field(ReaderLinkedField(
                    name: "weight",
                    concreteType: "PokemonDimension",
                    plural: false,
                    selections: [
                        .field(ReaderScalarField(
                            name: "minimum"
                        )),
                        .field(ReaderScalarField(
                            name: "maximum"
                        )),
                    ]
                )),
                .field(ReaderLinkedField(
                    name: "height",
                    concreteType: "PokemonDimension",
                    plural: false,
                    selections: [
                        .field(ReaderScalarField(
                            name: "minimum"
                        )),
                    ]
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
        var weight: PokemonDimension_weight?
        var height: PokemonDimension_height?

        init(from data: SelectorData) {
            name = data.get(String?.self, "name")
            number = data.get(String?.self, "number")
            classification = data.get(String?.self, "classification")
            weight = data.get(PokemonDimension_weight?.self, "weight")
            height = data.get(PokemonDimension_height?.self, "height")
        }

        struct PokemonDimension_weight: Readable {
            var minimum: String?
            var maximum: String?

            init(from data: SelectorData) {
                minimum = data.get(String?.self, "minimum")
                maximum = data.get(String?.self, "maximum")
            }

        }
        struct PokemonDimension_height: Readable {
            var minimum: String?

            init(from data: SelectorData) {
                minimum = data.get(String?.self, "minimum")
            }

        }
    }
}

protocol PokemonListRow_pokemon_Key {
    var fragment_PokemonListRow_pokemon: FragmentPointer { get }
}

