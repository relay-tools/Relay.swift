import Relay

private let query = graphql("""
query MoviesTabQuery {
  ...MoviesList_films
}
""")
