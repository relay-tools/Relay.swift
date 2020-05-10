import SwiftUI
import RelaySwiftUI

private let query = graphql("""
query MoviesTabQuery {
  ...MoviesList_films
}
""")

struct MoviesTab: View {
    var body: some View {
        RelayQuery(
            op: MoviesTabQuery(),
            variables: .init(),
            loadingContent: LoadingView(),
            errorContent: ErrorView.init,
            dataContent: Data.init
        )
            .tabItem {
                VStack {
                    Image(systemName: "film.fill")
                    Text("Movies")
                }
            }
    }

    struct Data: View {
        let data: MoviesTabQuery.Data?

        var body: some View {
            Group {
                if data == nil {
                    EmptyView()
                } else {
                    MoviesList(films: data!)
                }
            }
        }
    }
}
