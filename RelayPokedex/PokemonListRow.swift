import SwiftUI
import RelaySwiftUI

private let pokemonFragment = graphql("""
fragment PokemonListRow_pokemon on Pokemon {
    name
    number
}
""")

struct PokemonListRow: View {
    @Fragment(PokemonListRow_pokemon.self) var pokemon

    init(pokemon: PokemonListRow_pokemon_Key) {
        $pokemon = pokemon
    }

    var body: some View {
        HStack {
            if pokemon != nil {
                Text(pokemon!.name ?? "(unknown)")
                    .font(.body)
                Spacer()
                Text(pokemon!.number ?? "")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
    }
}
