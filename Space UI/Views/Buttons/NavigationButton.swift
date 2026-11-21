import SwiftUI

/// Per-window page navigation. A model (rather than a closure in the environment) so readers compare it by
/// identity and don't invalidate on every update; `UIRootView` mirrors it into `@SceneStorage` for restoration.
@MainActor @Observable
final class PageNavigator {
    var stackBottomPage: Page = .defaultPage

    func setPage(_ page: Page) {
        stackBottomPage = page
    }
}

extension Page {

    /// The page's name as words — "Power Management" from `powerManagement`. Derived rather than listed so
    /// the tvOS target's own, much smaller `Page` gets it from the same code.
    var accessibilityLabel: String {
        rawValue.reduce(into: "") { words, character in
            if words.isEmpty {
                words.append(contentsOf: character.uppercased())
            } else {
                if character.isUppercase { words.append(" ") }
                words.append(character)
            }
        }
    }

}

struct NavigationButton<Label: View>: View {
    
    @Environment(\.shapeDirection) var shapeDirection: ShapeDirection
    @Environment(PageNavigator.self) private var pageNavigator

    let label: Label
    var page: Page

    var body: some View {
        Button {
            AudioController.shared.play(.button)
            pageNavigator.setPage(page)
        } label: {
            label
        }
        .autoButtonStyle(shapeDirection: shapeDirection)
        // The generated label is the page's raw value clipped to six characters ("powerM"), drawn in a
        // sci-fi face — unreadable to VoiceOver, and no handle at all for the screenshot walk.
        .accessibilityLabel(page.accessibilityLabel)
        .accessibilityIdentifier("Page.\(page.rawValue)")
    }
    
    init(to page: Page, @ViewBuilder label: () -> Label) {
        self.page = page
        self.label = label()
    }
}

extension NavigationButton where Label == Text {
    init(to page: Page) {
        self.page = page
        self.label = Text(page.rawValue.prefix(6))
    }
}

#Preview {
    NavigationButton(to: .ticTacToe) {
        Text("Label")
    }
    .environment(PageNavigator())
}
