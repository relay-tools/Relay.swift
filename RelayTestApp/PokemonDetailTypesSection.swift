import SwiftUI
import RelaySwiftUI

private let pokemonFragment = graphql("""
fragment PokemonDetailTypesSection_pokemon on Pokemon {
    types
    resistant
    weaknesses
}
""")

struct PokemonDetailTypesSection: View {
    let pokemon: PokemonDetailTypesSection_pokemon_Key

    var body: some View {
        RelayFragment(fragment: PokemonDetailTypesSection_pokemon(),
                      key: pokemon,
                      content: contentView)
    }

    func contentView(_ data: PokemonDetailTypesSection_pokemon.Data) -> some View {
        Section(header: Text("Types")) {
            HStack {
                Text("Types")
                Spacer()
                if data.types == nil {
                    Text("(unknown)")
                } else {
                    Text(data.types!.map { $0 ?? "(unknown)" }.joined(separator: ", "))
                }
            }
            HStack {
                Text("Resistant To")
                Spacer()
                if data.resistant == nil {
                    Text("(unknown)")
                } else {
                    Text(data.resistant!.map { $0 ?? "(unknown)" }.joined(separator: ", "))
                        .multilineTextAlignment(.trailing)
                }
            }
            HStack {
                Text("Weak To")
                Spacer()
                if data.weaknesses == nil {
                    Text("(unknown)")
                } else {
                    Text(data.weaknesses!.map { $0 ?? "(unknown)" }.joined(separator: ", "))
                }
            }
        }
    }
}
