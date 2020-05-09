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
    var body: some View {
        NavigationView {
            RelayQuery(
                op: MoviesListQuery(),
                variables: .init(),
                loadingContent: LoadingView(),
                errorContent: ErrorView.init,
                dataContent: Data.init
            ).navigationBarTitle("Movies")
        }
    }

    private struct Data: View {
        let data: MoviesListQuery.Data?

        var films: [Film] {
            data?.allFilms?.edges?.compactMap { $0?.node } ?? []
        }

        var body: some View {
            List(films) { node in
                MoviesListRow(film: node)
            }
        }
    }
}


private typealias Film = MoviesListQuery.Data.FilmsConnection_allFilms.FilmsEdge_edges.Film_node

extension Film: Identifiable {}
