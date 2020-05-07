import SwiftUI
import RelaySwiftUI

struct PokemonDetailInfoSection: View {
    let pokemon: PokemonDetailInfoSection_pokemon_Key

    var body: some View {
        RelayFragment(
            fragment: PokemonDetailInfoSection_pokemon(),
            key: pokemon,
            content: contentView)
    }

    func contentView(_ data: PokemonDetailInfoSection_pokemon.Data) -> some View {
        Section(header: Text("Details")) {
            HStack {
                Text("Name")
                Spacer()
                Text(data.name ?? "(unknown)")
            }
            HStack {
                Text("Number")
                Spacer()
                Text(data.number ?? "(unknown)")
            }
            HStack {
                Text("Classification")
                Spacer()
                Text(data.classification ?? "(unknown)")
            }
        }
    }
}
