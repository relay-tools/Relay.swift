import SwiftUI
import RelaySwiftUI

private let query = graphql("""
query MoviesTabQuery {
  ...MoviesList_films
}
""")

struct MoviesTab: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct MoviesTab_Previews: PreviewProvider {
    static var previews: some View {
        MoviesTab()
    }
}
