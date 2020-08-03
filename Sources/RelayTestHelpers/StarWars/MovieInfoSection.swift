import Relay

private let filmFragment = graphql("""
fragment MovieInfoSection_film on Film
@refetchable(queryName: "MovieInfoSectionRefetchQuery")
{
  id
  episodeID
  title
  director
  releaseDate
}
""")

public enum MovieInfoSection {
    public static let refetchEvenNewerHope = """
{
  "data": {
    "node": {
      "id": "ZmlsbXM6MQ==",
      "episodeID": 4,
      "title": "An Even Newer Hope",
      "director": "George Lucas",
      "releaseDate": "1977-05-25",
      "__typename": "Film"
    }
  }
}
"""

    public static let refetchEmpire = """
{
  "data": {
    "node": {
      "id": "ZmlsbXM6Mg==",
      "episodeID": 5,
      "title": "The Empire Strikes Back",
      "director": "Irvin Kershner",
      "releaseDate": "1980-05-17",
      "__typename": "Film"
    }
  }
}
"""
}
