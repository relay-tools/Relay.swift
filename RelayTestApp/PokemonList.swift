import SwiftUI
import RelaySwiftUI

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
        List(data?.pokemons ?? [], id: \.id) { pokemon in
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
