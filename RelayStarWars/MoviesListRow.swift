import SwiftUI
import RelaySwiftUI

private let filmFragment = graphql("""
fragment MoviesListRow_film on Film {
  id
  title
}
""")

struct MoviesListRow: View {
    let film: MoviesListRow_film_Key

    var body: some View {
        RelayFragment(
            fragment: MoviesListRow_film(),
            key: film,
            content: Content.init
        )
    }

    private struct Content: View {
        let film: MoviesListRow_film.Data

        var body: some View {
            Text(film.title ?? "Unknown")
        }
    }
}
