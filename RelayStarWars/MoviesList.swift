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
    @PaginationFragmentNext<MoviesList_films> var films
    let onRefetch: () -> Void
    
    init(films: PaginationFragmentNext<MoviesList_films>, onRefetch: @escaping () -> Void) {
        self._films = films
        self.onRefetch = onRefetch
    }

    var body: some View {
        NavigationView {
            List {
                if let films = films {
                    ForEach(films.allFilms?.compactMap { $0 } ?? []) { node in
                        MoviesListRow(film: node.asFragment())
                    }

                    if films.isLoadingNext {
                        Text("Loading more…")
                            .foregroundColor(.secondary)
                    } else if films.hasNext == true {
                        Button {
                            films.loadNext(3)
                        } label: {
                            Label("Load more…", systemImage: "ellipsis.circle.fill")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }
            .navigationBarTitle("Movies")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        onRefetch()
                    } label: { Image(systemName: "arrow.clockwise") }
                }
            }
        }
    }
}

