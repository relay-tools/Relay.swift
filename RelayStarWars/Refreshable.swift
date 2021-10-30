import SwiftUI

struct CompatibleRefreshable: ViewModifier {
    let action: @Sendable () async -> Void

    @State private var inFlight = false

    func body(content: Content) -> some View {
        if #available(iOS 15, *) {
            content.refreshable(action: action)
        } else {
            content.toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        inFlight = true
                        Task {
                            await action()
                            inFlight = false
                        }
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                    .disabled(inFlight)
                }
            }
        }
    }
}

extension View {
    func compatibleRefreshable(action: @escaping @MainActor @Sendable () async -> Void) -> some View {
        modifier(CompatibleRefreshable(action: action))
    }
}
