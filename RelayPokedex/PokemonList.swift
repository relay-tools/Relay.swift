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
    @Query(PokemonListQuery.self) var query

    var body: some View {
        NavigationView {
            Group {
                if query.isLoading {
                    Text("Loading…")
                } else if query.error != nil {
                    ErrorView(error: query.error!)
                } else {
                    List(pokemons, id: \.id) { pokemon in
                        NavigationLink(destination: PokemonDetail(id: pokemon.id, name: pokemon.name ?? "")) {
                            PokemonListRow(pokemon: pokemon)
                        }
                    }
                }
            }.navigationBarTitle("Pokédex")
        }
    }

    private var pokemons: [PokemonListQuery.Data.Pokemon_pokemons] {
        (query.data?.pokemons ?? []).compactMap { $0 }
    }
}

struct PokemonList_Previews: PreviewProvider {
    static var previews: some View {
        PokemonList()
    }
}
