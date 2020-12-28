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
    @Fragment<PokemonDetailTypesSection_pokemon> var pokemon

    var body: some View {
        Group {
            if let pokemon = pokemon {
                Section(header: Text("Types")) {
                    HStack {
                        Text("Types")
                        Spacer()
                        if let types = pokemon.types {
                            Text(types.map { $0 ?? "(unknown)" }.joined(separator: ", "))
                        } else {
                            Text("(unknown)")
                        }
                    }
                    HStack {
                        Text("Resistant To")
                        Spacer()
                        if let resistant = pokemon.resistant {
                            Text(resistant.map { $0 ?? "(unknown)" }.joined(separator: ", "))
                                .multilineTextAlignment(.trailing)
                        } else {
                            Text("(unknown)")
                        }
                    }
                    HStack {
                        Text("Weak To")
                        Spacer()
                        if let weaknesses = pokemon.weaknesses {
                            Text(weaknesses.map { $0 ?? "(unknown)" }.joined(separator: ", "))
                        } else {
                            Text("(unknown)")
                        }
                    }
                }
            }
        }
    }
}
