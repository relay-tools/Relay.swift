import SwiftUI
import RelaySwiftUI

private let filmsFragment = graphql("""
fragment MoviesList_films on Root
@argumentDefinitions(
  count: { type: "Int", defaultValue: 3 },
  cursor: { type: "String" },
)
@refetchable(queryName: "MoviesListPaginationQuery") {
  allFilms(first: $count, after: $cursor)
  @connection(key: "MoviesList_allFilms") {
    edges {
      node {
        id
        ...MoviesListRow_film
      }
    }
  }
}
""")

struct MoviesList: View {
    let films: MoviesList_films_Key

    var body: some View {
        NavigationView {
            RelayPaginationFragment(
                fragment: MoviesList_films(),
                key: films,
                content: Content.init
            ).navigationBarTitle("Movies")
        }
    }

    private struct Content: View {
        let data: MoviesList_films.Data?
        let paging: Paginating

        var films: [Film] {
            data?.allFilms?.edges?.compactMap { $0?.node } ?? []
        }

        var body: some View {
            List {
                ForEach(films) { node in
                    MoviesListRow(film: node)
                }

                if paging.isLoadingNext {
                    Text("Loading more…")
                        .foregroundColor(.secondary)
                } else if paging.hasNext == true {
                    Button("Load more…") {
                        NSLog("loading more")
                        self.paging.loadNext(3)
                    }
                }
            }
        }
    }
}


private typealias Film = MoviesList_films.Data.FilmsConnection_allFilms.FilmsEdge_edges.Film_node

extension Film: Identifiable {}
