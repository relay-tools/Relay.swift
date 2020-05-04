//
//  PokemonList.swift
//  RelayTestApp
//
//  Created by Matt Moriarity on 5/3/20.
//  Copyright © 2020 Matt Moriarity. All rights reserved.
//

import SwiftUI
import RelaySwiftUI

struct PokemonList: View {
    var body: some View {
        RelayQuery(op: PokemonListQuery(), variables: .init(), loadingContent: Text("Loading…"), errorContent: errorView, dataContent: dataView)
    }

    func errorView(_ error: Error) -> some View {
        ErrorView(error: error)
    }

    func dataView(_ data: PokemonListQuery.Response) -> some View {
        List(data.pokemons, id: \.id) { pokemon in
            Text(pokemon.name ?? "")
        }
    }
}

struct PokemonList_Previews: PreviewProvider {
    static var previews: some View {
        PokemonList()
    }
}
