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
    @Query(CurrentUserToDoListQuery.self) var query

    var body: some View {
        Group {
            if query.isLoading {
                Text("Loading...")
            } else if query.error != nil {
                Text("Error: \(query.error!.localizedDescription)")
            } else if query.data?.user != nil {
                ToDoList(user: query.data!.user!)
                    .navigationBarTitle("To-do List for \(query.data!.user!.id)")
            }
        }
    }
}
