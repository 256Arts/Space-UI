import SwiftUI

struct SudokuPage: View {
    
    enum CellContent: String {
        case a, b, c, d
    }
    
    static let buttonLength: CGFloat = 100.0
    
    let boardLength = 4
    
    @Environment(\.system) private var system
    @Environment(AppController.self) private var appController

    @State var puzzleBoard: [[CellContent?]] = [
        [.a, nil, nil, nil],
        [nil, .b, nil, nil],
        [nil, nil, .c, nil],
        [nil, nil, nil, .d]
    ]
    
    var body: some View {
        PuzzleGridView(rows: boardLength, columns: boardLength, cellLength: SudokuPage.buttonLength) { coord in
            makeButton(coord: coord)
        }
    }
    
    func makeButton(coord: GridCoord) -> some View {
        let cellContent = puzzleBoard[coord.row][coord.column]
        
        return Button(action: {
            self.selectCell(coord: coord)
        }) {
            ZStack {
                Rectangle()
                    .foregroundColor(.clear)
                Text(cellContent?.rawValue ?? "")
            }
        }
        .foregroundColor(coord.row == coord.column ? nil : system.colors.color(.secondary, opacity: .max))
        .font(Font.spaceFont(size: 40))
        .frame(width: SudokuPage.buttonLength, height: SudokuPage.buttonLength, alignment: .center)
    }
    
    func selectCell(coord: GridCoord) {
        let newValue: CellContent = {
            switch puzzleBoard[coord.row][coord.column] {
            case .a:
                return .b
            case .b:
                return .c
            case .c:
                return .d
            default:
                return .a
            }
        }()
        puzzleBoard[coord.row][coord.column] = newValue
        checkSuccess()
    }
    
    func checkSuccess() {
        if puzzleBoard.allSatisfy({ Set($0) == [.a, .b, .c, .d] }) {
            for col in 0..<boardLength {
                let colArray = [
                    puzzleBoard[0][col],
                    puzzleBoard[1][col],
                    puzzleBoard[2][col],
                    puzzleBoard[3][col]
                ]
                if Set(colArray) != [.a, .b, .c, .d] {
                    return
                }
            }
            appController.solveEmergencyPuzzle()
        }
    }
    
}

#Preview {
    SudokuPage()
}
