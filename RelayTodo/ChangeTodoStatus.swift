import Relay
import RelaySwiftUI

private let mutation = graphql("""
mutation ChangeTodoStatusMutation($input: ChangeTodoStatusInput!) {
    changeTodoStatus(input: $input) {
        todo {
            id
            complete
        }
    }
}
""")

extension Mutation.Mutator where Operation == ChangeTodoStatusMutation {
    func commit(id: String, complete: Bool) {
        commit(
            variables: .init(input: .init(
                complete: complete,
                id: id,
                userId: "me"
            )),
            optimisticResponse: [
                "changeTodoStatus": [
                    "todo": [
                        "id": id,
                        "complete": complete,
                    ]
                ]
            ]
        )
    }
}
