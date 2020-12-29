import Combine
import Foundation
import Nimble

func waitUntilComplete<Publisher: Combine.Publisher>(timeout: DispatchTimeInterval = AsyncDefaults.timeout, _ publisher: Publisher, file: FileString = #file, line: UInt = #line) {
    waitUntil(timeout: timeout, file: file, line: line) { done in
        var handle: AnyCancellable?
        handle = publisher.sink(receiveCompletion: { _ in
            done()
            handle?.cancel()
        }, receiveValue: { _ in })
    }
}
