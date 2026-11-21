import SwiftUI

struct UnlabeledKeypadPage: View {
    
    private let cellLength: CGFloat = 100
    private let solution: String = {
        let chars = "abcdefghi"
        return String(chars.randomElement()!) + String(chars.randomElement()!) + String(chars.randomElement()!) + String(chars.randomElement()!)
    }()
    
    @Environment(\.system) private var system
    @Environment(AppController.self) private var appController

    @State var keypadText = "****"
    @State var incorrectCodeEntered = false
    
    var body: some View {
        VStack {
            Text(solution)
                .font(Font.spaceFont(size: 40))
            Text(self.keypadText)
                .font(Font.spaceFont(size: 40))
                .foregroundColor(incorrectCodeEntered ? system.colors.color(.danger, opacity: .max) : nil)
            PuzzleGridView(rows: 3, columns: 3, cellLength: cellLength) { coord in
                makeButton(char: letter(for: coord))
            }
        }
    }

    /// The keypad's cells are the letters a–i laid out row-major.
    private func letter(for coord: GridCoord) -> Character {
        let letters = "abcdefghi"
        return letters[letters.index(letters.startIndex, offsetBy: coord.row * 3 + coord.column)]
    }

    func makeButton(char: Character) -> some View {
        Button {
            self.selectCell(char: char)
        } label: {
            EmptyView()
        }
        .contentShape(Rectangle())
        .frame(width: cellLength, height: cellLength, alignment: .center)
    }
    
    func selectCell(char: Character) {
        guard let nextIndex = keypadText.firstIndex(of: "*") else { return }
        keypadText.insert(char, at: nextIndex)
        keypadText.removeLast()
        if keypadText == solution {
            appController.solveEmergencyPuzzle()
        } else if !keypadText.contains("*") {
            incorrectCodeEntered = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.keypadText = "****"
                self.incorrectCodeEntered = false
            }
        }
    }
    
}

#Preview {
    UnlabeledKeypadPage()
}
