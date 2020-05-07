import SwiftUI
import RelaySwiftUI

struct PokemonDetail: View {
    let id: String
    let name: String

    var body: some View {
        RelayQuery(
            op: PokemonDetailQuery(),
            variables: .init(id: id),
            loadingContent: Text("Loading…"),
            errorContent: errorView,
            dataContent: dataView
        ).navigationBarTitle(name)
    }

    func errorView(_ error: Error) -> some View {
        Text(error.localizedDescription)
            .foregroundColor(.red)
    }

    func dataView(_ data: PokemonDetailQuery.Data?) -> some View {
        Group {
            if data?.pokemon == nil {
                EmptyView()
            } else {
                List {
                    PokemonDetailInfoSection(pokemon: data!.pokemon!)
                }.listStyle(GroupedListStyle())
            }
        }
    }
}
