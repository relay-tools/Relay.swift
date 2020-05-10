import Relay

struct PokemonListQuery: Relay.Operation {
    var node: ConcreteRequest {
        ConcreteRequest(
            fragment: ReaderFragment(
                name: "PokemonListQuery",
                selections: [
                    .field(ReaderLinkedField(
                        name: "pokemons",
                        args: [LiteralArgument(name: "first", value: 50)],
                        concreteType: "Pokemon",
                        plural: true,
                        selections: [
                            .field(ReaderScalarField(name: "__typename")),
                            .field(ReaderScalarField(name: "id")),
                            .fragmentSpread(ReaderFragmentSpread(name: "PokemonListRow_pokemon"))]))]),
            operation: NormalizationOperation(
                name: "PokemonListQuery",
                argumentDefinitions: [],
                selections: [
                    .field(NormalizationLinkedField(
                        name: "pokemons",
                        args: [
                            LiteralArgument(name: "first", value: 50)],
                        concreteType: "Pokemon",
                        plural: true,
                        selections: [
                            .field(NormalizationScalarField(name: "id")),
                            .field(NormalizationScalarField(name: "name")),
                            .field(NormalizationScalarField(name: "number")),
                            .field(NormalizationScalarField(name: "classification"))]))]),
            params: RequestParameters(
                name: "PokemonListQuery",
                operationKind: .query,
                text: """
query PokemonListQuery {
    pokemons(first: 50) {
        __typename
        id
        ...PokemonListRow_pokemon
    }
}

fragment PokemonListRow_pokemon on Pokemon {
    name
    number
    classification
}
"""))
    }

    struct Variables: Relay.Variables {
        var asDictionary: [String : Any] { [:] }
    }

    struct Data: Readable {
        var pokemons: [Pokemon]

        init(from data: SelectorData) {
            pokemons = data.get([Pokemon].self, "pokemons")
        }

        struct Pokemon: Readable, PokemonListRow_pokemon_Key {
            var id: String
            var __typename: String
            var fragment_PokemonListRow_pokemon: FragmentPointer

            init(from data: SelectorData) {
                id = data.get(String.self, "id")
                __typename = data.get(String.self, "__typename")
                fragment_PokemonListRow_pokemon = data.get(fragment: "PokemonListRow_pokemon")
            }
        }
    }
}
