import SwiftUI
import RelaySwiftUI
import Foundation

private let filmFragment = graphql("""
fragment MoviesListRow_film on Film {
  id
  episodeID
  title
  director
  releaseDate
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
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Episode \(film.episodeID!):")
                        Text(film.title!)
                    }.font(.headline)
                    Text("Directed by \(film.director!)")
                        .font(.footnote)
                }
                Spacer()
                Text(film.releaseYear)
                    .font(.callout)
                    .foregroundColor(.secondary)
            }.padding(.vertical, 4)
        }
    }
}

extension MoviesListRow_film.Data {
    var releaseYear: String {
        String(releaseDate!.split(separator: "-").first!)
    }
}
