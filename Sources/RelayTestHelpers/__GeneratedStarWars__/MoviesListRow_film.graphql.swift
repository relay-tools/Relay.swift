// Auto-generated by relay-compiler. Do not edit.

import Relay

public struct MoviesListRow_film {
    public var fragmentPointer: FragmentPointer

    public init(key: MoviesListRow_film_Key) {
        fragmentPointer = key.fragment_MoviesListRow_film
    }

    public static var node: ReaderFragment {
        ReaderFragment(
            name: "MoviesListRow_film",
            type: "Film",
            selections: [
                .field(ReaderScalarField(
                    name: "id"
                )),
                .field(ReaderScalarField(
                    name: "episodeID"
                )),
                .field(ReaderScalarField(
                    name: "title"
                )),
                .field(ReaderScalarField(
                    name: "director"
                )),
                .field(ReaderScalarField(
                    name: "releaseDate"
                ))
            ]
        )
    }
}

extension MoviesListRow_film {
    public struct Data: Decodable, Identifiable {
        public var id: String
        public var episodeID: Int?
        public var title: String?
        public var director: String?
        public var releaseDate: String?
    }
}

public protocol MoviesListRow_film_Key {
    var fragment_MoviesListRow_film: FragmentPointer { get }
}

extension MoviesListRow_film: Relay.Fragment {}

#if canImport(RelaySwiftUI)
import RelaySwiftUI

extension MoviesListRow_film_Key {
    public func asFragment() -> RelaySwiftUI.Fragment<MoviesListRow_film> {
        RelaySwiftUI.Fragment<MoviesListRow_film>(self)
    }
}
#endif