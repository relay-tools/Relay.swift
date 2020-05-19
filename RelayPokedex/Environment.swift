import Combine
import Foundation
import Relay

private let url = URL(string: "https://graphql-pokemon.now.sh/")!

let store = Store(source: DefaultRecordSource())

let environment = Environment(
    network: MyNetwork(),
    store: store
)

class MyNetwork: Network {
    func execute(request: RequestParameters, variables: VariableData, cacheConfig: CacheConfig) -> AnyPublisher<Data, Error> {
        var req = URLRequest(url: url)
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
