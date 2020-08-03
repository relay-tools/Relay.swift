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

public enum MovieDetailNode {
    public static let newHope = """
{
  "data": {
    "node": {
      "__typename": "Film",
      "id": "ZmlsbXM6MQ==",
      "episodeID": 4,
      "title": "A New Hope",
      "director": "George Lucas",
      "releaseDate": "1977-05-25",
      "characterConnection": {
        "edges": [
          {
            "node": {
              "id": "cGVvcGxlOjE=",
              "name": "Luke Skywalker"
            }
          },
          {
            "node": {
              "id": "cGVvcGxlOjI=",
              "name": "C-3PO"
            }
          },
          {
            "node": {
              "id": "cGVvcGxlOjM=",
              "name": "R2-D2"
            }
          }
        ]
      }
    }
  }
}
"""

    public static let lukeSkywalker = """
{
  "data": {
    "node": {
      "__typename": "Person",
      "id": "cGVvcGxlOjE="
    }
  }
}
"""
}
