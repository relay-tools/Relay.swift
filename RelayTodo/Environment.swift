import Combine
import Foundation
import Relay

private let graphqlURL = URL(string: "http://localhost:3000/graphql")!

let store = Store(source: DefaultRecordSource())

let environment = Environment(
    network: Network(),
    store: store
)

class Network: Relay.Network {
    func execute(request: RequestParameters, variables: VariableData, cacheConfig: CacheConfig) -> AnyPublisher<Data, Error> {
        var req = URLRequest(url: graphqlURL)
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpMethod = "POST"

        do {
            let payload = RequestPayload(query: request.text ?? "", operationName: request.name, variables: variables)
            req.httpBody = try JSONEncoder().encode(payload)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }

        return URLSession.shared.dataTaskPublisher(for: req)
            .map { $0.data }
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
}

struct RequestPayload<Vars: Encodable>: Encodable {
    var query: String
    var operationName: String
    var variables: Vars
}

