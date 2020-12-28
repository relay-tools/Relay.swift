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
    @Query<PokemonListQuery> var query

    var body: some View {
        NavigationView {
            Group {
                switch query.get() {
                case .loading:
                    Text("Loading…")
                case .failure(let error):
                    ErrorView(error: error)
                case .success(let data):
                    if let pokemons = (data?.pokemons ?? []).compactMap { $0 } {
                        List(pokemons) { pokemon in
                            NavigationLink(destination: PokemonDetail(id: pokemon.id, name: pokemon.name ?? "")) {
                                PokemonListRow(pokemon: pokemon.asFragment())
                            }
                        }
                    }
                }
            }.navigationBarTitle("Pokédex")
        }
    }
}

struct PokemonList_Previews: PreviewProvider {
    static var previews: some View {
        PokemonList()
    }
}
