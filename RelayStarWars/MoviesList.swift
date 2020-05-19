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
    @PaginationFragment(MoviesList_films.self) var films

    init(films: MoviesList_films_Key) {
        $films = films
    }

    private var filmNodes: [Film] {
        films?.allFilms?.edges?.compactMap { $0?.node } ?? []
    }

    var body: some View {
        NavigationView {
            List {
                if films != nil {
                    ForEach(filmNodes) { node in
                        MoviesListRow(film: node)
                    }

                    if films!.isLoadingNext {
                        Text("Loading more…")
                            .foregroundColor(.secondary)
                    } else if films!.hasNext == true {
                        Button("Load more…") {
                            self.films!.loadNext(3)
                        }
                    }
                }
            }.navigationBarTitle("Movies")
        }
    }
}


private typealias Film = MoviesList_films.Data.FilmsConnection_allFilms.FilmsEdge_edges.Film_node

extension Film: Identifiable {}
