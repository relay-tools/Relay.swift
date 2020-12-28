import SwiftUI
import RelaySwiftUI

private let pokemonFragment = graphql("""
fragment PokemonListRow_pokemon on Pokemon {
    name
    number
}
""")

struct PokemonListRow: View {
    @Fragment<PokemonListRow_pokemon> var pokemon

    var body: some View {
        HStack {
            if let pokemon = pokemon {
                Text(pokemon.name ?? "(unknown)")
                    .font(.body)
                Spacer()
                Text(pokemon.number ?? "")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
    }
}
