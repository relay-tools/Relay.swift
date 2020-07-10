import Relay

private let query = graphql("""
query MovieDetailQuery($id: ID!) {
    film(id: $id) {
        ...MovieInfoSection_film
    }
}
""")
