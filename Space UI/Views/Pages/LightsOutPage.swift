import SwiftUI

struct LightsOutPage: View {
    
    static let buttonLength: CGFloat = 100.0
    
    let boardLength = 3
    
    @Environment(AppController.self) private var appController

    @State var puzzleBoard: [[Bool]] = {
        var board = [[Bool]]()
        for _ in 0..<3 {
            board.append([Bool.random(), Bool.random(), Bool.random()])
        }
        return board
    }()
    
    var body: some View {
        PuzzleGridView(rows: boardLength, columns: boardLength, cellLength: LightsOutPage.buttonLength) { coord in
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
                if cellContent {
                    Text("ON")
                }
            }
        }
        .font(Font.spaceFont(size: 40))
        .frame(width: LightsOutPage.buttonLength, height: LightsOutPage.buttonLength, alignment: .center)
    }
    
    func selectCell(coord: GridCoord) {
        puzzleBoard[coord.row][coord.column].toggle()
        if 0 <= coord.row-1 {
            puzzleBoard[coord.row-1][coord.column].toggle()
        }
        if 0 <= coord.column-1 {
            puzzleBoard[coord.row][coord.column-1].toggle()
        }
        if coord.row+1 < boardLength {
            puzzleBoard[coord.row+1][coord.column].toggle()
        }
        if coord.column+1 < boardLength {
            puzzleBoard[coord.row][coord.column+1].toggle()
        }
        checkSuccess()
    }
    
    func checkSuccess() {
        if puzzleBoard.allSatisfy({ !$0.contains(false) }) {
            appController.solveEmergencyPuzzle()
        }
    }
    
}

#Preview {
    LightsOutPage()
}
