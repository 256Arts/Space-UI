import SwiftUI

#if targetEnvironment(macCatalyst)

/// App-wide pointer auto-hide (video-player style): the cursor is revealed on any movement and hidden again once
/// the pointer sits still for `idleDelay`. `NSCursor.hide()` is app-wide and reference-counted, so a single shared
/// owner keeps exactly one hide/unhide outstanding — per-window owners would unbalance the global count.
@MainActor
final class CursorAutoHider {

    static let shared = CursorAutoHider()

    /// How long the pointer must sit still before it hides.
    var idleDelay: Duration = .seconds(3)

    private var idleTask: Task<Void, Never>?
    private var isHidden = false

    /// Report pointer movement (or a window appearing). Reveals the cursor and restarts the idle countdown.
    func pointerMoved() {
        show()
        idleTask?.cancel()
        idleTask = Task { @MainActor in
            try? await Task.sleep(for: idleDelay)
            guard !Task.isCancelled, !isHidden else { return }
            NSCursor.hide()
            isHidden = true
        }
    }

    /// Reveals the cursor if we hid it, keeping the app-wide hide count balanced.
    func show() {
        guard isHidden else { return }
        NSCursor.unhide()
        isHidden = false
    }
}

private struct CursorAutoHideModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onContinuousHover { phase in
                if case .active = phase {
                    CursorAutoHider.shared.pointerMoved()
                }
                // Ignore `.ended`: the pointer may just be crossing into another of the app's views, and the OS
                // already shows the system cursor whenever it leaves the app's content entirely.
            }
            .onAppear {
                CursorAutoHider.shared.pointerMoved()
            }
    }
}

extension View {
    /// Enables app-wide cursor auto-hide for this view's window (Mac Catalyst only; a no-op on other platforms).
    func cursorAutoHide() -> some View {
        modifier(CursorAutoHideModifier())
    }
}

#else

extension View {
    func cursorAutoHide() -> some View { self }
}

#endif
