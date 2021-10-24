import SwiftUI
import Relay

public typealias QueryFetchPolicy = Relay.FetchPolicy

/// A property wrapper type for loading data for a GraphQL query in a SwiftUI view.
///
/// A query will usually map one-to-one to a screen of your app. The query can fetch all of the data needed to render that screen in one roundtrip to the server, using ``Fragment``s to provide the data that each child view needs.
@propertyWrapper
public struct Query<O: Relay.Operation>: DynamicProperty {
    @SwiftUI.Environment(\.queryResource) var queryResource
    @SwiftUI.Environment(\.fragmentResource) var fragmentResource
    @StateObject var loader = QueryLoader<O>()

    let fetchPolicy: QueryFetchPolicy

    /// Create a new query property.
    ///
    /// ## Example
    ///
    /// ```swift
    /// struct MyView: View {
    ///     @Query<MyViewQuery>(fetchPolicy: .storeAndNetwork) var query
    /// }
    /// ```
    ///
    /// - Parameter fetchPolicy: The policy for when to use cached data and when to fetch new data from the server. By default, queries always fetch new data from the server.
    public init(fetchPolicy: QueryFetchPolicy = .networkOnly) {
        self.fetchPolicy = fetchPolicy
    }

    public init(_ type: O.Type, fetchPolicy: QueryFetchPolicy = .networkOnly) {
        self.init(fetchPolicy: fetchPolicy)
    }

    /// The value provided by a ``Query`` property.
    public var wrappedValue: WrappedValue {
        WrappedValue(query: self)
    }

    /// A type providing access to a query's data.
    public struct WrappedValue {
        let query: Query<O>

        /// Access the current data for the query.
        ///
        /// Query data is loaded lazily when it's first needed by the view. The first time ``get(_:fetchKey:)`` is called,
        /// Relay will make a request to load the necessary data and will indicate this by returning ``Query/Result/loading``. When the data has been loaded, the view will update, and the next call will
        /// return ``Query/Result/success(_:)`` with the data, allowing the view to use it to build the UI. If the data
        /// cannot be fetched, it will instead return ``Query/Result/failure(_:)`` with the error that occurred.
        ///
        /// Variables can be passed in from `@State` or other properties. If the variables have changed from a previous call,
        /// the query data will be refetched with the new variables. If you need to refetch the data without changing the query's
        /// variables, you can use the optional `fetchKey` parameter. If the fetch key is changed from the previous call, the
        /// query data will be refetched.
        ///
        /// - Parameters:
        ///     - variables: The values of variables that your GraphQL query expects. The Relay compiler will generate the appropriate struct for this. If your query does not take any variables, you can omit this parameter (see ``get(fetchKey:)``).
        ///     - fetchKey: An optional opaque value that will trigger a refetch of data from the server when it changes from its previous value.
        /// - Returns: A ``Query/Result`` representing the current state of the query.
        public func get(_ variables: O.Variables, fetchKey: Any? = nil) -> Result {
            switch query.loader.loadIfNeeded(
                resource: query.queryResource!,
                fragmentResource: query.fragmentResource!,
                variables: variables,
                fetchPolicy: query.fetchPolicy,
                fetchKey: fetchKey
            ) {
            case nil:
                return .loading
            case .failure(let error):
                return .failure(error)
            case .success:
                if let data = query.loader.data {
                    return .success(data)
                } else {
                    return .loading
                }
            }
        }

        /// Refetch the query's data from the server.
        ///
        /// This is an alternative to using the `fetchKey` parameter in ``get(_:fetchKey:)``. It allows imperatively
        /// requesting that updated data be fetched. It's an async method that returns when the new data has been fetched
        /// or has failed to fetch successfully. You can use ``refetch()`` to add pull-to-refresh to a list using the
        /// `refreshable` view modifier.
        ///
        /// ```swift
        /// List(todos) { todo in
        ///     ToDoRow(todo: todo)
        /// }
        /// .refreshable {
        ///     await query.refetch()
        /// }
        /// ```
        public func refetch() async {
            await query.loader.refetch()
        }
    }

    /// The loading state of a ``Query``.
    ///
    /// Initially, a query is ``loading``, indicating that it is currently fetch data and doesn't have any to show. If the query is
    /// able to successfully load the data it needs, the state will transition to ``success(_:)`` including the data that the
    /// query loaded. If the query is unable to load the data it needs, the state will transition to ``failure(_:)`` including
    /// an error.
    ///
    /// This is returned by ``Query/WrappedValue-swift.struct/get(_:fetchKey:)`` to provide a SwiftUI view
    /// with the current state of its query. In almost all cases, the right way to use this is to use a `switch` statement to ensure
    /// that the view builds an appropriate UI for each possible state.
    public enum Result {
        /// The query is attempting to load the data it needs.
        case loading
        /// The query tried to load data and failed.
        ///
        /// The associated error value will indicate what went wrong in trying to load the data.
        case failure(Error)
        /// The query successfully loaded the data it needs.
        ///
        /// The data that was loaded is included as associated value. The type of the data will be a struct generated by
        /// the Relay compiler with fields that match the selections of the GraphQL query.
        case success(O.Data?)

        public var isLoading: Bool {
            if case .loading = self {
                return true
            }
            return false
        }

        public var error: Error? {
            if case .failure(let error) = self {
                return error
            }
            return nil
        }

        public var data: O.Data? {
            if case .success(let data) = self {
                return data
            }
            return nil
        }
    }
}

extension Query.WrappedValue where O.Variables == EmptyVariables {
    /// Access the current data for a query.
    ///
    /// This is a variant of ``get(_:fetchKey:)`` for queries which do not use any variables.
    ///
    /// - Parameter fetchKey: An optional opaque value that will trigger a refetch of data from the server when it changes from its previous value.
    /// - Returns: A ``Query/Result`` representing the current state of the query.
    public func get(fetchKey: Any? = nil) -> Query.Result {
        get(.init(), fetchKey: fetchKey)
    }
}
