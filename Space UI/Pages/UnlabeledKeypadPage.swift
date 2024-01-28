//
//  UnlabeledKeypadPage.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2020-06-16.
//  Copyright © 2020 256 Arts Developer. All rights reserved.
//

import SwiftUI

struct UnlabeledKeypadPage: View {
    
    private let cellLength: CGFloat = 100
    private let solution: String = {
        let chars = "abcdefghi"
        return String(chars.randomElement()!) + String(chars.randomElement()!) + String(chars.randomElement()!) + String(chars.randomElement()!)
    }()
    
    @State var keypadText = "****"
    @State var incorrectCodeEntered = false
    
    var body: some View {
        VStack {
            Text(solution)
                .font(Font.spaceFont(size: 40))
            Text(self.keypadText)
                .font(Font.spaceFont(size: 40))
                .foregroundColor(incorrectCodeEntered ? Color(color: .danger, opacity: .max) : nil)
            ZStack {
                GridShape(rows: 3, columns: 3, outsideCornerRadius: system.cornerRadius(forLength: cellLength))
                    .stroke(Color(color: .primary, opacity: .max), style: system.strokeStyle(.thin))
                Grid(horizontalSpacing: 0, verticalSpacing: 0) {
                    GridRow {
                        makeButton(char: "a")
                        makeButton(char: "b")
                        makeButton(char: "c")
                    }
                    GridRow {
                        makeButton(char: "d")
                        makeButton(char: "e")
                        makeButton(char: "f")
                    }
                    GridRow {
                        makeButton(char: "g")
                        makeButton(char: "h")
                        makeButton(char: "i")
                    }
                }
                .clipShape(GridShape(rows: 3, columns: 3, outsideCornerRadius: system.cornerRadius(forLength: cellLength)))
            }
            .frame(width: cellLength * 3, height: cellLength * 3, alignment: .center)
        }
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
            PeerSessionController.shared.send(message: .emergencyEnded)
            ShipData.shared.endEmergency()
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
