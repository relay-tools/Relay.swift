import Combine

class Executor<Op: Operation> {
    let op: Op
    let source: AnyPublisher<GraphQLResponse<Op.Response>, Error>

    init(operation: Op,
         source: AnyPublisher<GraphQLResponse<Op.Response>, Error>) {
        self.op = operation
        self.source = source
    }

    func execute() -> AnyPublisher<GraphQLResponse<Op.Response>, Error> {
        return source
    }
}
