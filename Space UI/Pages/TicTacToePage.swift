//
//  TicTacToePage.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2019-12-15.
//  Copyright © 2019 256 Arts Developer. All rights reserved.
//

import SwiftUI
import JaydenCodeGenerator

struct TicTacToePage: View {
    
    enum CellOwner {
        case player, opponent
    }
    struct CellCoord: Equatable {
        let row: Int
        let column: Int
    }
    struct Line {
        let c1: CellCoord
        let c2: CellCoord
        let c3: CellCoord
    }
    
    let playerName = "YOU"
    let opponentName = "AI"
    
    @IDGen private var idGen
    
    @State var winLine: Line?
    @State var ticTacToeBoard: [[CellOwner?]] = [
        [nil, nil, nil],
        [nil, nil, nil],
        [nil, nil, nil]
    ]
    @State var playerWins = 0
    @State var opponentWins = 0
    
    var jaydenCode: String {
        JaydenCodeGenerator.generateCode(secret: "O4ZW0020EC")
    }
    
    var body: some View {
        VStack {
            HStack(spacing: 16) {
                NavigationButton(to: .lockScreen)
            }
            .frame(idealWidth: system.shapeButtonFrameWidth, maxWidth: 2 * system.shapeButtonFrameWidth, idealHeight: system.shapeButtonFrameHeight, maxHeight: 2 * system.shapeButtonFrameHeight, alignment: .center)
            Spacer()
            ZStack {
                GridShape(rows: 3, columns: 3, outsideCornerRadius: system.cornerRadius(forLength: 100))
                    .stroke(Color(color: .primary, opacity: .max), style: system.strokeStyle(.thin))
                Grid(horizontalSpacing: 0, verticalSpacing: 0) {
                    GridRow {
                        makeButton(coord: CellCoord(row: 0, column: 0))
                        makeButton(coord: CellCoord(row: 0, column: 1))
                        makeButton(coord: CellCoord(row: 0, column: 2))
                    }
                    GridRow {
                        makeButton(coord: CellCoord(row: 1, column: 0))
                        makeButton(coord: CellCoord(row: 1, column: 1))
                        makeButton(coord: CellCoord(row: 1, column: 2))
                    }
                    GridRow {
                        makeButton(coord: CellCoord(row: 2, column: 0))
                        makeButton(coord: CellCoord(row: 2, column: 1))
                        makeButton(coord: CellCoord(row: 2, column: 2))
                    }
                }
                .clipShape(GridShape(rows: 3, columns: 3, outsideCornerRadius: system.cornerRadius(forLength: 100)))
            }
                .frame(width: 300, height: 300, alignment: .center)
            AutoStack {
                TextPair(did: idGen(0), label: playerName, value: "\(playerWins)", largerFontSize: 32)
                TextPair(did: idGen(0), label: opponentName, value: "\(opponentWins)", largerFontSize: 32)
                if playerWins >= 10 {
                    Text("Secret Code: \(jaydenCode)")
                }
            }
                .frame(height: 60)
            Spacer()
        }
        .frame(idealWidth: .infinity, maxWidth: .infinity)
        .widgetCorners(did: idGen(1), topLeading: true, topTrailing: true, bottomLeading: true, bottomTrailing: true)
    }
    
    func makeButton(coord: CellCoord) -> some View {
        let cellOwner = ticTacToeBoard[coord.row][coord.column]
        let cellIsOnWinLine = (coord == winLine?.c1 || coord == winLine?.c2 || coord == winLine?.c3)
        
        return ZStack {
                Rectangle()
                    .foregroundColor(cellIsOnWinLine ? Color(color: .primary, opacity: .medium) : .clear)
                Text(cellOwner == nil ? "" : (cellOwner == .player ? playerName : opponentName))
                    .foregroundColor(cellOwner == .player ? nil : Color(color: .tertiary, opacity: .max))
                    .font(Font.spaceFont(size: 40))
            }
            .frame(width: 100, height: 100, alignment: .center)
            .contentShape(Rectangle())
            .onTapGesture {
                selectCell(coord: coord)
            }
    }
    
    func selectCell(coord: CellCoord) {
        guard winLine == nil, ticTacToeBoard[coord.row][coord.column] == nil else {
            AudioController.shared.play(.notAllowed)
            return
        }
        AudioController.shared.play(.button)
        ticTacToeBoard[coord.row][coord.column] = .player
        if let winLine = checkGameover() {
            self.winLine = winLine
            Timer.scheduledTimer(withTimeInterval: 0.7, repeats: false) { (_) in
                self.winLine = nil
                self.playerWins += 1
                self.clearBoard()
            }
        } else {
            opponentTurn()
            if let winLine = checkGameover() {
                self.winLine = winLine
                Timer.scheduledTimer(withTimeInterval: 0.7, repeats: false) { (_) in
                    self.winLine = nil
                    self.opponentWins += 1
                    self.clearBoard()
                }
            }
        }
    }
    
    func checkGameover() -> Line? {
        
        func checkLine(_ line: Line) -> Bool {
            let cell1 = ticTacToeBoard[line.c1.row][line.c1.column]
            if cell1 != nil, cell1 == ticTacToeBoard[line.c2.row][line.c2.column], cell1 == ticTacToeBoard[line.c3.row][line.c3.column] {
                return true
            } else {
                return false
            }
        }
        
        let allLines = [
            Line(c1: CellCoord(row: 0, column: 0), c2: CellCoord(row: 0, column: 1), c3: CellCoord(row: 0, column: 2)),
            Line(c1: CellCoord(row: 1, column: 0), c2: CellCoord(row: 1, column: 1), c3: CellCoord(row: 1, column: 2)),
            Line(c1: CellCoord(row: 2, column: 0), c2: CellCoord(row: 2, column: 1), c3: CellCoord(row: 2, column: 2)),
            Line(c1: CellCoord(row: 0, column: 0), c2: CellCoord(row: 1, column: 0), c3: CellCoord(row: 2, column: 0)),
            Line(c1: CellCoord(row: 0, column: 1), c2: CellCoord(row: 1, column: 1), c3: CellCoord(row: 2, column: 1)),
            Line(c1: CellCoord(row: 0, column: 2), c2: CellCoord(row: 1, column: 2), c3: CellCoord(row: 2, column: 2)),
            Line(c1: CellCoord(row: 0, column: 0), c2: CellCoord(row: 1, column: 1), c3: CellCoord(row: 2, column: 2)),
            Line(c1: CellCoord(row: 0, column: 2), c2: CellCoord(row: 1, column: 1), c3: CellCoord(row: 2, column: 0))
        ]
        for line in allLines {
            if checkLine(line) { return line }
        }
        return nil
    }
    
    func clearBoard() {
        ticTacToeBoard[0][0] = nil
        ticTacToeBoard[0][1] = nil
        ticTacToeBoard[0][2] = nil
        ticTacToeBoard[1][0] = nil
        ticTacToeBoard[1][1] = nil
        ticTacToeBoard[1][2] = nil
        ticTacToeBoard[2][0] = nil
        ticTacToeBoard[2][1] = nil
        ticTacToeBoard[2][2] = nil
    }
    
    func opponentTurn() {
        var emptyCells = [CellCoord]()
        for r in 0...2 {
            for c in 0...2 {
                if ticTacToeBoard[r][c] == nil {
                    emptyCells.append(CellCoord(row: r, column: c))
                }
            }
        }
        if let opponentCell = emptyCells.randomElement() {
            ticTacToeBoard[opponentCell.row][opponentCell.column] = .opponent
        } else {
            clearBoard()
        }
    }
    
}

#Preview {
    TicTacToePage()
}
