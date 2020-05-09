import SwiftUI
import RelaySwiftUI

private let query = graphql("""
query PokemonListQuery {
    pokemons(first: 50) {
        __typename
        id
        name
        ...PokemonListRow_pokemon
    }
}
""")

struct PokemonList: View {
    var body: some View {
        NavigationView {
            RelayQuery(
                op: PokemonListQuery(),
                variables: .init(),
                loadingContent: Text("Loading…"),
                errorContent: errorView,
                dataContent: dataView
            ).navigationBarTitle("Pokédex")
        }
    }

    func errorView(_ error: Error) -> some View {
        ErrorView(error: error)
    }

    func dataView(_ data: PokemonListQuery.Data?) -> some View {
        let pokemons = (data?.pokemons ?? []).compactMap { $0 }
        return List(pokemons, id: \.id) { pokemon in
            NavigationLink(destination: PokemonDetail(id: pokemon.id, name: pokemon.name ?? "")) {
                PokemonListRow(pokemon: pokemon)
            }
        }
    }
}

struct PokemonList_Previews: PreviewProvider {
    static var previews: some View {
        PokemonList()
    }
}
