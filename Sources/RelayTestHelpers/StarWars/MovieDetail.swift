import Relay

private let query = graphql("""
query MovieDetailQuery($id: ID!) {
    film(id: $id) {
        ...MovieInfoSection_film
    }
}
""")

public enum MovieDetail {
    public static let newHope = """
{
  "data": {
    "film": {
      "id": "ZmlsbXM6MQ==",
      "episodeID": 4,
      "title": "A New Hope",
      "director": "George Lucas",
      "releaseDate": "1977-05-25",
      "__typename": "Film"
    }
  }
}
"""
}
