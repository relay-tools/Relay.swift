import SwiftUI
import RelaySwiftUI

private let query = graphql("""
query MoviesTabQuery {
  ...MoviesList_films
}
""")

struct MoviesTab: View {
    @Query(MoviesTabQuery.self) var movies
    
    var body: some View {
        Group {
            if movies.isLoading {
                LoadingView()
            } else if movies.error != nil {
                ErrorView(error: movies.error!)
            } else if movies.data != nil {
                MoviesList(films: movies.data!)
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
