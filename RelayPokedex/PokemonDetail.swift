import SwiftUI
import RelaySwiftUI

private let query = graphql("""
query PokemonDetailQuery($id: String) {
    pokemon(id: $id) {
        id
        ...PokemonDetailInfoSection_pokemon
        ...PokemonDetailTypesSection_pokemon
    }
}
""")

struct PokemonDetail: View {
    @Query<PokemonDetailQuery> var query
    let id: String
    let name: String

    var body: some View {
        Group {
            switch query.get(id: id) {
            case .loading:
                Text("Loading…")
            case .failure(let error):
                ErrorView(error: error)
            case .success(let data):
                if let pokemon = data?.pokemon {
                    List {
                        PokemonDetailInfoSection(pokemon: pokemon.asFragment())
                        PokemonDetailTypesSection(pokemon: pokemon.asFragment())
                    }.listStyle(GroupedListStyle())
                }
            }
        }.navigationBarTitle(name)
    }
}
