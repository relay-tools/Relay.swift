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
