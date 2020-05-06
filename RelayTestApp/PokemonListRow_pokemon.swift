import Relay

struct PokemonListRow_pokemon {
    var node: ReaderFragment {
        ReaderFragment(
            name: "PokemonListRow_pokemon",
            selections: [
                .field(ReaderScalarField(name: "id")),
                .field(ReaderScalarField(name: "name")),
                .field(ReaderScalarField(name: "number")),
                .field(ReaderScalarField(name: "classification"))])
    }

    struct Variables: Encodable {
    }

    struct Data {
        var id: String
        var name: String?
        var number: String?
        var classification: String?

        init(record: RecordProxy) {
            id = try record.get("id")
            name = try record.get("name")
            number = try record.get("number")
            classification = try record.get("classification")
        }
    }
}

protocol PokemonListRow_pokemon_Key: Record {
    var fragment_PokemonListRow_pokemon: PokemonListRow_pokemon.Variables { get }
    // TODO owner
}
