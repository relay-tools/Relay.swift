import Relay

private let query = graphql("""
query MovieDetailNodeQuery($id: ID!) {
    node(id: $id) {
        id
        ...on Film {
            episodeID
            title
            director
            releaseDate

            characterConnection(first: 3) {
                edges {
                    node {
                        id
                        name
                    }
                }
            }
        }
    }
}
""")
