import SwiftUI
import RelaySwiftUI

private let query = graphql("""
query MoviesTabQuery {
  ...MoviesList_films
}
""")

struct MoviesTab: View {
    @QueryNext<MoviesTabQuery> var movies
    
    var body: some View {
        Group {
            switch movies.get() {
            case .loading:
                LoadingView()
            case .failure(let error):
                ErrorView(error: error)
            case .success(let data):
                if let data = data {
                    MoviesList(films: data.asFragment())
                }
            }
        }
        .tabItem {
            VStack {
                Image(systemName: "film.fill")
                Text("Movies")
            }
        }
    }
}
