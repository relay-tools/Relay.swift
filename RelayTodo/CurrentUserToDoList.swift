import SwiftUI
import RelaySwiftUI

private let query = graphql("""
query CurrentUserToDoListQuery {
    user(id: "me") {
        id
        ...ToDoList_user
    }
}
""")

struct CurrentUserToDoList: View {
    @Query<CurrentUserToDoListQuery> var query

    var body: some View {
        switch query.get() {
        case .loading:
            Text("Loading...")
        case .failure(let error):
            Text("Error: \(error.localizedDescription)")
        case .success(let data):
            if let user = data?.user {
                ToDoList(user: user.asFragment())
                    .navigationBarTitle("To-do List for \(user.id)")
            }
        }
    }
}
