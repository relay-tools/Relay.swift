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
            if pokemon != nil {
                Section(header: Text("Types")) {
                    HStack {
                        Text("Types")
                        Spacer()
                        if pokemon!.types == nil {
                            Text("(unknown)")
                        } else {
                            Text(pokemon!.types!.map { $0 ?? "(unknown)" }.joined(separator: ", "))
                        }
                    }
                    HStack {
                        Text("Resistant To")
                        Spacer()
                        if pokemon!.resistant == nil {
                            Text("(unknown)")
                        } else {
                            Text(pokemon!.resistant!.map { $0 ?? "(unknown)" }.joined(separator: ", "))
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    HStack {
                        Text("Weak To")
                        Spacer()
                        if pokemon!.weaknesses == nil {
                            Text("(unknown)")
                        } else {
                            Text(pokemon!.weaknesses!.map { $0 ?? "(unknown)" }.joined(separator: ", "))
                        }
                    }
                }
            }
        }
    }
}
