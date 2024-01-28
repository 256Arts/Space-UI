//
//  SudokuPage.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2020-06-16.
//  Copyright © 2020 256 Arts Developer. All rights reserved.
//

import SwiftUI

struct SudokuPage: View {
    
    enum CellContent: String {
        case a, b, c, d
    }
    
    static let buttonLength: CGFloat = 100.0
    
    let boardLength = 4
    
    @State var puzzleBoard: [[CellContent?]] = [
        [.a, nil, nil, nil],
        [nil, .b, nil, nil],
        [nil, nil, .c, nil],
        [nil, nil, nil, .d]
    ]
    
    var body: some View {
        ZStack {
            GridShape(rows: boardLength, columns: boardLength, outsideCornerRadius: system.cornerRadius(forLength: SudokuPage.buttonLength))
                .stroke(Color(color: .primary, opacity: .max), style: system.strokeStyle(.thin))
            Grid(horizontalSpacing: 0, verticalSpacing: 0) {
                GridRow {
                    makeButton(coord: GridCoord(row: 0, column: 0))
                    makeButton(coord: GridCoord(row: 0, column: 1))
                    makeButton(coord: GridCoord(row: 0, column: 2))
                    makeButton(coord: GridCoord(row: 0, column: 3))
                }
                GridRow {
                    makeButton(coord: GridCoord(row: 1, column: 0))
                    makeButton(coord: GridCoord(row: 1, column: 1))
                    makeButton(coord: GridCoord(row: 1, column: 2))
                    makeButton(coord: GridCoord(row: 1, column: 3))
                }
                GridRow {
                    makeButton(coord: GridCoord(row: 2, column: 0))
                    makeButton(coord: GridCoord(row: 2, column: 1))
                    makeButton(coord: GridCoord(row: 2, column: 2))
                    makeButton(coord: GridCoord(row: 2, column: 3))
                }
                GridRow {
                    makeButton(coord: GridCoord(row: 3, column: 0))
                    makeButton(coord: GridCoord(row: 3, column: 1))
                    makeButton(coord: GridCoord(row: 3, column: 2))
                    makeButton(coord: GridCoord(row: 3, column: 3))
                }
            }
            .clipShape(GridShape(rows: boardLength, columns: boardLength, outsideCornerRadius: system.cornerRadius(forLength: SudokuPage.buttonLength)))
        }
        .frame(width: SudokuPage.buttonLength * CGFloat(boardLength), height: SudokuPage.buttonLength * CGFloat(boardLength), alignment: .center)
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
        .foregroundColor(coord.row == coord.column ? nil : Color(color: .secondary, opacity: .max))
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
            PeerSessionController.shared.send(message: .emergencyEnded)
            ShipData.shared.endEmergency()
        }
    }
    
}

#Preview {
    SudokuPage()
}
