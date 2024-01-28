//
//  SoundController.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2019-12-19.
//  Copyright © 2019 256 Arts Developer. All rights reserved.
//

import AVKit
import Combine

final class AudioController {
    
    enum AbstractSound {
        case action, button, notAllowed, message
        // Loops
        case alarmLoop, sonarLoop
    }
    
    enum Resource: String {
        case action, action2, button, button2, button3, notAllowed, message
        // Loops
        case alarmLoop, alarmHighLoop, sonarLoop
        // Ambience
        case cargoBayAmbience, shipPassBy10, beeps, dataStream, powerDown, cyberChime2, hullBreach2
        case r2Talk1, r2Talk2, r2Talk3, r2Talk4, r2Talk5, r2Talk6, r2Talk7, r2Talk8, r2Talk9, r2Talk10, r2Talk11, r2Talk12, r2Talk13, r2Talk14, r2Talk15, r2Talk16
    }
    
    static let shared = AudioController()
    
    private var secondaryAudioCancellable: AnyCancellable?
    private var ambientSoundTimer1: Timer?
    private var ambientSoundTimer2: Timer?
    
    private var playAmbience: Bool {
        UserDefaults.standard.bool(forKey: UserDefaults.Key.playAmbience)
    }
    private var playSounds: Bool {
        UserDefaults.standard.bool(forKey: UserDefaults.Key.playSounds)
    }
    
    private var actionSound = AVAudioPlayer.make(resource: .action)
    private var buttonSound = AVAudioPlayer.make(resource: .button)
    private let notAllowedSound = AVAudioPlayer.make(resource: .notAllowed)
    private let messageSound = AVAudioPlayer.make(resource: .message)
    
    private var alarmLoopSound = AVAudioPlayer.make(resource: .alarmLoop)
    private let sonarLoopSound = AVAudioPlayer.make(resource: .sonarLoop)
    
    private let cargoBayAmbienceSound = AVAudioPlayer.make(resource: .cargoBayAmbience, fileType: "m4a")
    private let shipPassBySound = AVAudioPlayer.make(resource: .shipPassBy10, fileType: "mp3")
    private let beepsSound = AVAudioPlayer.make(resource: .beeps)
    private let cyberChimeSound = AVAudioPlayer.make(resource: .cyberChime2, fileType: "mp3")
    private let hullBreachSound = AVAudioPlayer.make(resource: .hullBreach2, fileType: "mp3")
    private let dataStreamSound = AVAudioPlayer.make(resource: .dataStream)
    private let powerDownSound = AVAudioPlayer.make(resource: .powerDown)
    
    private let r2Talk1Sound = AVAudioPlayer.make(resource: .r2Talk1)
    private let r2Talk2Sound = AVAudioPlayer.make(resource: .r2Talk2)
    private let r2Talk3Sound = AVAudioPlayer.make(resource: .r2Talk3)
    private let r2Talk4Sound = AVAudioPlayer.make(resource: .r2Talk4)
    private let r2Talk5Sound = AVAudioPlayer.make(resource: .r2Talk5)
    private let r2Talk6Sound = AVAudioPlayer.make(resource: .r2Talk6)
    private let r2Talk7Sound = AVAudioPlayer.make(resource: .r2Talk7)
    private let r2Talk8Sound = AVAudioPlayer.make(resource: .r2Talk8)
    private let r2Talk9Sound = AVAudioPlayer.make(resource: .r2Talk9)
    private let r2Talk10Sound = AVAudioPlayer.make(resource: .r2Talk10)
    private let r2Talk11Sound = AVAudioPlayer.make(resource: .r2Talk11)
    private let r2Talk12Sound = AVAudioPlayer.make(resource: .r2Talk12)
    private let r2Talk13Sound = AVAudioPlayer.make(resource: .r2Talk13)
    private let r2Talk14Sound = AVAudioPlayer.make(resource: .r2Talk14)
    private let r2Talk15Sound = AVAudioPlayer.make(resource: .r2Talk15)
    private let r2Talk16Sound = AVAudioPlayer.make(resource: .r2Talk16)
    
    init() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [])
        } catch {
            print("failed to set audio category")
        }
        secondaryAudioCancellable = NotificationCenter.default
            .publisher(for: AVAudioSession.silenceSecondaryAudioHintNotification)
            .sink { notification in self.handleSecondaryAudio(notification) }
        
        beepsSound?.volume = 0.5
        cargoBayAmbienceSound?.volume = 0.0
        cyberChimeSound?.volume = 0.5
        hullBreachSound?.volume = 0.5
        dataStreamSound?.volume = 0.1
        powerDownSound?.volume = 0.6
        
        alarmLoopSound?.numberOfLoops = -1
        sonarLoopSound?.numberOfLoops = -1
        cargoBayAmbienceSound?.numberOfLoops = -1
    }
    
    func makeSoundsForSystem() {
        actionSound = AVAudioPlayer.make(resource: system.actionSoundResource)
        buttonSound = AVAudioPlayer.make(resource: system.buttonSoundResource)
        alarmLoopSound = AVAudioPlayer.make(resource: system.alarmSoundResource)
        
        if system.buttonSoundResource == .button {
            buttonSound?.volume = 0.8
        }
    }
    
    func play(_ abstractSound: AbstractSound) {
        guard playSounds else { return }
        
        let sound: AVAudioPlayer? = {
            switch abstractSound {
            case .action:
                return actionSound
            case .button:
                return buttonSound
            case .notAllowed:
                return notAllowedSound
            case .message:
                return messageSound
            case .alarmLoop:
                return alarmLoopSound
            case .sonarLoop:
                return sonarLoopSound
            }
        }()
        if sound?.isPlaying == true {
            sound?.currentTime = 0.0
        } else {
            sound?.play()
        }
    }
    
    func stopLoopingSound(_ abstractSound: AbstractSound) {
        let sound: AVAudioPlayer? = {
            switch abstractSound {
            case .alarmLoop:
                return alarmLoopSound
            case .sonarLoop:
                return sonarLoopSound
            default:
                return nil
            }
        }()
        sound?.stop()
    }
    
    func startAmbience() {
        let playingAudio = AVAudioSession.sharedInstance().secondaryAudioShouldBeSilencedHint
        guard playAmbience, !playingAudio else { return }
        
        cargoBayAmbienceSound?.play()
        cargoBayAmbienceSound?.setVolume(1, fadeDuration: 1)
        scheduleNextAmbientSound(slot: 1)
        scheduleNextAmbientSound(slot: 2)
    }
    
    func stopAmbience() {
        cargoBayAmbienceSound?.setVolume(0, fadeDuration: 1)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.cargoBayAmbienceSound?.stop()
        }
        invalidateAmbientSoundTimers()
    }
    
    func invalidateAmbientSoundTimers() {
        ambientSoundTimer1?.invalidate()
        ambientSoundTimer2?.invalidate()
    }
    
    func scheduleNextAmbientSound(slot: Int) {
        let timer = Timer.scheduledTimer(withTimeInterval: TimeInterval.random(in: 10..<300), repeats: false) { (_) in
            switch Int.random(in: 0..<46) {
            case ..<5:
                self.beepsSound?.play()
            case ..<10:
                self.shipPassBySound?.play()
            case ..<15:
                self.cyberChimeSound?.play()
            case ..<20:
                self.hullBreachSound?.play()
            case ..<25:
                self.dataStreamSound?.play()
            case ..<30:
                self.powerDownSound?.play()
            case 30:
                self.r2Talk1Sound?.play()
            case 31:
                self.r2Talk2Sound?.play()
            case 32:
                self.r2Talk3Sound?.play()
            case 33:
                self.r2Talk4Sound?.play()
            case 34:
                self.r2Talk5Sound?.play()
            case 35:
                self.r2Talk6Sound?.play()
            case 36:
                self.r2Talk7Sound?.play()
            case 37:
                self.r2Talk8Sound?.play()
            case 38:
                self.r2Talk9Sound?.play()
            case 39:
                self.r2Talk10Sound?.play()
            case 40:
                self.r2Talk11Sound?.play()
            case 41:
                self.r2Talk12Sound?.play()
            case 42:
                self.r2Talk13Sound?.play()
            case 43:
                self.r2Talk14Sound?.play()
            case 44:
                self.r2Talk15Sound?.play()
            default:
                self.r2Talk16Sound?.play()
            }
            self.scheduleNextAmbientSound(slot: slot)
        }
        if slot == 1 {
            self.ambientSoundTimer1 = timer
        } else {
            self.ambientSoundTimer2 = timer
        }
    }
    
    func handleSecondaryAudio(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionSilenceSecondaryAudioHintTypeKey] as? UInt,
            let type = AVAudioSession.SilenceSecondaryAudioHintType(rawValue: typeValue) else {
                return
        }
        if type == .begin {
            // Other app started playing audio
            stopAmbience()
        } else {
            startAmbience()
        }
    }
    
}

extension AVAudioPlayer {
    
    static func make(resource: AudioController.Resource, fileType: String = "wav") -> AVAudioPlayer? {
        if let url = Bundle.main.url(forResource: resource.rawValue, withExtension: fileType) {
            do {
                return try self.init(contentsOf: url, fileTypeHint: fileType)
            } catch {
                print("Failed to load sound.")
            }
        }
        return nil
    }
    
}

