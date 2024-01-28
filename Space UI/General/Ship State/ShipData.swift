//
//  ShipData.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2020-01-06.
//  Copyright © 2020 256 Arts Developer. All rights reserved.
//

import SwiftUI
import GameplayKit

final class ShipData: ObservableObject {
    
    final class StatusState: ObservableObject {
        @Published var binary1: Int
        @Published var circleIconName1: String
        @Published var circleIconName2: String
        @Published var circleIconName3: String
        @Published var binary2: Int
        
        init(binary1: Int, circleIconName1: String, circleIconName2: String, circleIconName3: String, binary2: Int) {
            self.binary1 = binary1
            self.circleIconName1 = circleIconName1
            self.circleIconName2 = circleIconName2
            self.circleIconName3 = circleIconName3
            self.binary2 = binary2
        }
    }
    final class PowerState: ObservableObject {
        @Published var shield1HasPower = true
        @Published var shield2HasPower = true
        @Published var comsHavePower = true
        @Published var engineHasPower = true
        @Published var weaponsHavePower = true
    }
    
    static let commandShipIconNames = (1...5).map({ "Cmd Ship \($0)" })
    static let starshipIconNames = (1...6).map({ "Starship \($0)" })
    
    static let shared = ShipData(seed: seed)
    
    // Misc
    let icon: Image
    let enemyCommandShipIconNames: [String]
    let enemyStarshipIconNames: [String]
    var isInEmergency = false
    
    // State
    var topStatusState: StatusState
    var bottomStatusState: StatusState
    var targetState: TargetState
    var powerState = PowerState()
    var nearbyShipsState: NearbyShipsState
    var messagesState = MessagesState()
    @Published var shieldAngle = 0.0
    @Published var weaponsInLaserMode = true
    
    init(seed: UInt64) {
        var shipIcons = Self.starshipIconNames
        let shipIconIndex = shipIcons.indices.randomElement()!
        icon = Image(shipIcons.remove(at: shipIconIndex)).resizable()
        enemyCommandShipIconNames = Self.commandShipIconNames
        enemyStarshipIconNames = shipIcons
        
        topStatusState = StatusState(binary1: Int.random(in: 0...31), circleIconName1: CircleIcon.allCases.randomElement()!.rawValue, circleIconName2: CircleIcon.allCases.randomElement()!.rawValue, circleIconName3: CircleIcon.allCases.randomElement()!.rawValue, binary2: Int.random(in: 0...31))
        bottomStatusState = StatusState(binary1: Int.random(in: 0...31), circleIconName1: CircleIcon.allCases.randomElement()!.rawValue, circleIconName2: CircleIcon.allCases.randomElement()!.rawValue, circleIconName3: CircleIcon.allCases.randomElement()!.rawValue, binary2: Int.random(in: 0...31))
        
        let random: GKRandom = {
            let source = GKMersenneTwisterRandomSource(seed: seed)
            return GKRandomDistribution(randomSource: source, lowestValue: 0, highestValue: Int.max)
        }()
        
        nearbyShipsState = NearbyShipsState(random: random)
        targetState = TargetState(random: random)
        
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            switch Int.random(in: 0..<10) {
            case 0:
                self.topStatusState.binary1 = Int.random(in: 0...31)
            case 1:
                self.topStatusState.circleIconName1 = CircleIcon.allCases.randomElement()!.rawValue
            case 2:
                self.topStatusState.circleIconName2 = CircleIcon.allCases.randomElement()!.rawValue
            case 3:
                self.topStatusState.circleIconName3 = CircleIcon.allCases.randomElement()!.rawValue
            case 4:
                self.topStatusState.binary2 = Int.random(in: 0...31)
            case 5:
                self.bottomStatusState.binary1 = Int.random(in: 0...31)
            case 6:
                self.bottomStatusState.circleIconName1 = CircleIcon.allCases.randomElement()!.rawValue
            case 7:
                self.bottomStatusState.circleIconName2 = CircleIcon.allCases.randomElement()!.rawValue
            case 8:
                self.bottomStatusState.circleIconName3 = CircleIcon.allCases.randomElement()!.rawValue
            default:
                self.bottomStatusState.binary2 = Int.random(in: 0...31)
            }
        }
    }
    
    func beginEmergency() {
        isInEmergency = true
        AudioController.shared.play(.alarmLoop)
        #if !os(tvOS)
        AppController.shared.savedPage = AppController.shared.visiblePage
        AppController.shared.visiblePage = {
            switch Int.random(in: 0..<3) {
            case 0:
                return .sudokuPuzzle
            case 1:
                return .lightsOutPuzzle
            default:
                return .unlabeledKeypadPuzzle
            }
        }()
        #endif
    }
    
    func endEmergency() {
        isInEmergency = false
        AudioController.shared.stopLoopingSound(.alarmLoop)
        #if !os(tvOS)
        AppController.shared.visiblePage = AppController.shared.savedPage
        #endif
    }
    
}
