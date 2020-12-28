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
    func commit(id: String, complete: Bool, onError: @escaping (Error) -> Void) {
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
            ],
            completion: { result in
                if case .failure(let error) = result {
                    onError(error)
                }
            }
        )
    }
}
