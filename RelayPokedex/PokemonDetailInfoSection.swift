import SwiftUI
import RelaySwiftUI

private let pokemonFragment = graphql("""
fragment PokemonDetailInfoSection_pokemon on Pokemon {
    name
    number
    classification
    weight {
        minimum
        maximum
    }
    height {
        minimum
        maximum
    }
}
""")

struct PokemonDetailInfoSection: View {
    @Fragment<PokemonDetailInfoSection_pokemon> var pokemon

    var body: some View {
        Group {
            if let pokemon = pokemon {
                Section(header: Text("Details")) {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(pokemon.name ?? "(unknown)")
                    }
                    HStack {
                        Text("Number")
                        Spacer()
                        Text(pokemon.number ?? "(unknown)")
                    }
                    HStack {
                        Text("Classification")
                        Spacer()
                        Text(pokemon.classification ?? "(unknown)")
                    }
                    HStack {
                        Text("Height")
                        Spacer()
                        Text("\(pokemon.height?.minimum ?? "(unknown)") - \(pokemon.height?.maximum ?? "(unknown)")")
                    }
                    HStack {
                        Text("Weight")
                        Spacer()
                        Text("\(pokemon.weight?.minimum ?? "(unknown)") - \(pokemon.weight?.maximum ?? "(unknown)")")
                    }
                }
            }
        }
    }
}
