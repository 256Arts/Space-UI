//
//  BinaryView.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2019-12-18.
//  Copyright © 2019 256 Arts Developer. All rights reserved.
//

import SwiftUI

extension Double {
    static func log(base: Double, of value: Double) -> Double {
        return log10(value) / log10(base)
    }
}

extension Int {
    static func numberOfDigits(for number: Int, inBase base: Int) -> Int {
        return Int(ceil(Double.log(base: Double(base), of: Double(1+number))))
    }
    
    static func representation(of number: Int, inBase base: Int, withDigitCount numberOfDigits: Int) -> [Int] {
        if numberOfDigits == 1 {
            return [number]
        } else {
            var array = representation(of: number/base, inBase: base, withDigitCount: numberOfDigits-1)
            array.append(number % base)
            return array
        }
    }
}

// Example of what this looks like:
// [X][X][ ][X][ ]

struct BinaryView: View {
    
    struct Character: Identifiable {
        private let index: Int
        let digitValue: Int
        
        var id: Int { index }
        var shapeDirection: ShapeDirection {
            index % 2 == 0 ? .up : .down
        }
        
        init(index: Int, digitValue: Int) {
            self.index = index
            self.digitValue = digitValue
        }
    }
    
    @Environment(\.elementSize) private var elementSize
    @EnvironmentObject private var systemStyles: SystemStyles
    
    var maxDigits: Int {
        switch elementSize {
        case .mini:
            return 3
        case .small:
            return 4
        case .regular:
            return 5
        case .large:
            return 6
        }
    }
    
    // Styles
    var characterLength: CGFloat {
        let base: CGFloat = {
            switch elementSize {
            case .small:
                return 22
            case .mini:
                return 18
            default:
                return 26
            }
        }()
        switch systemStyles.basicShape {
        case .triangle, .diamond:
            return round(base * 1.16)
        case .trapezoid:
            return round(base * 1.08)
        default:
            return base
        }
    }
    var spacing: CGFloat {
        switch systemStyles.basicShape {
        case .triangle:
            return -2
        case .trapezoid:
            return 2
        default:
            return 10
        }
    }
    
    // Math
    var value = 0
    var maxValue = 0
    var base = 2
    private var digits: [Int] {
        let digitCount = (maxValue == 0) ? 6 : Int.numberOfDigits(for: maxValue, inBase: base)
        return Array(Int.representation(of: value, inBase: base, withDigitCount: digitCount).prefix(maxDigits))
    }
    private var characters: [Character] {
        digits.enumerated().map({ Character(index: $0.offset, digitValue: $0.element) })
    }
    
    var body: some View {
        HStack(spacing: systemStyles.basicShape == .triangle ? 0 : 10) {
            ForEach(characters) { char in
                AutoShape(direction: char.shapeDirection)
                    .foregroundColor(systemStyles.binaryNumberColors[char.digitValue].fill)
                    .frame(width: characterLength, height: characterLength, alignment: .center)
                    .overlay {
                        if systemStyles.binaryNumberColors[char.digitValue].border != nil {
                            AutoShape(direction: char.shapeDirection)
                                .strokeBorder(Color(color: .primary, opacity: .max), style: systemStyles.strokeStyle(.thin))
                                .frame(width: characterLength, height: characterLength, alignment: .center)
                        }
                    }
            }
        }
    }
}

#Preview {
    BinaryView()
}
