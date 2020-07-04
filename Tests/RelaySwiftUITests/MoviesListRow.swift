import Relay

private let filmFragment = graphql("""
fragment MoviesListRow_film on Film {
  id
  episodeID
  title
  director
  releaseDate
}
""")
