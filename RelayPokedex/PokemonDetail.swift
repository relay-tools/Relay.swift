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
    @Query(PokemonDetailQuery.self) var query
    let name: String

    init(id: String, name: String) {
        self.name = name
        $query = .init(id: id)
    }

    var body: some View {
        Group {
            if query.isLoading {
                Text("Loading…")
            } else if query.error != nil {
                ErrorView(error: query.error!)
            } else if query.data?.pokemon != nil {
                List {
                    PokemonDetailInfoSection(pokemon: query.data!.pokemon!)
                    PokemonDetailTypesSection(pokemon: query.data!.pokemon!)
                }.listStyle(GroupedListStyle())
            }
        }.navigationBarTitle(name)
    }
}
