import SwiftUI
import RelaySwiftUI

private let query = graphql("""
query MoviesTabQuery {
  ...MoviesList_films
}
""")

struct MoviesTab: View {
    @Query<MoviesTabQuery> var movies
//    @State var fetchKey = UUID()
    
    var body: some View {
        NavigationView {
            switch movies.get() {
            case .loading:
                LoadingView()
            case .failure(let error):
                ErrorView(error: error)
            case .success(let data):
                if let data = data {
                    MoviesList(films: data.asFragment()) {
                        await movies.refetch()
                    }
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
