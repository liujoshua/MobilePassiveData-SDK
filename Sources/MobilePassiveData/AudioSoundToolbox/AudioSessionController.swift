//
//  AudioSessionController.swift
//
//  Copyright © 2017-2021 Sage Bionetworks. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2.  Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors
// may be used to endorse or promote products derived from this software without
// specific prior written permission. No license is granted to the trademarks of
// the copyright holders even if such marks are included in this software.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

import Foundation

/// `AudioSessionActivity` is a UI controller that needs to be able to start/stop the audio session
/// while allowing *other* activities to use the audio session concurrently.
public protocol AudioSessionActivity : class {
    
    /// A short string that uniquely identifies the activity.
    var identifier: String { get }
}

#if canImport(AVFoundation) && !os(macOS)

import AVFoundation

/// The audio session controller for iOS applications that use background audio. This allows
/// different processes within this app to set the audio session requirements for their background
/// action or assessment. If you access the AVAudioSession without using this controller, it may
/// well get clobbered by another activity.
public final class AudioSessionController {
    public static let shared: AudioSessionController = AudioSessionController()

    /// The audio session is a shared pointer to the current audio session (if running). This is
    /// used to allow background audio. Background audio is required in order for an active step
    /// to play sound such as voice commands to a participant who make not be looking at their
    /// screen.
    ///
    /// For example, a "Walk and Balance" task that measures gait and balance by having the
    /// participant walk back and forth followed by having them turn in a circle would require
    /// turning on background audio in order to play spoken instructions even if the screen is
    /// locked before putting the phone in the participant's pocket.
    ///
    /// - note: The application settings will need to include setting capabilities appropriate for
    /// background audio if this feature is used.
    ///
    public private(set) var audioSession: AVAudioSession?
    
    /// The current audio session settings.
    public private(set) var currentSettings: AudioSessionSettings?
    
    private var activityMapping: [String : AudioSessionSettings] = [:]
    private var orderedIdentifiers: [String] = []
    private var backgroundAudioIdentifiers: Set<String> = []
    private var silencePlayer: SilencePlayer?
    
    /// Background audio can be used to keep an activity running if the screen is locked because of
    /// the idle timer turning off the device screen or the user locking the phone before placing
    /// it in their pocket.
    ///
    /// -note: If the app uses background audio, then the developer will need to turn `ON` the
    /// "Background Modes" under the "Capabilities" tab of the Xcode project, and will need to
    /// select "Audio, AirPlay, and Picture in Picture".
    public func startBackgroundAudioIfNeeded(on activity: AudioSessionActivity) {
        backgroundAudioIdentifiers.insert(activity.identifier)
        _startAudioSessionIfNeeded(.backgroundSilence)
        _startBackgroundSilenceIfNeeded()
    }

    /// Start the audio session if needed. This will look to see if `audioSession` is already
    /// started, what the current settings are, and modify them or start a new session if needed.
    /// - parameters:
    ///     - activity: The activity that is calling the controller.
    ///     - settings: The settings required by the calling activity.
    public func startAudioSessionIfNeeded(on activity: AudioSessionActivity,
                                          with settings: AudioSessionSettings = AudioSessionSettings()) {
        guard activityMapping[activity.identifier] == nil else { return }
        activityMapping[activity.identifier] = settings
        orderedIdentifiers.append(activity.identifier)
        _startAudioSessionIfNeeded(settings)
    }
    
    private func _startAudioSessionIfNeeded(_ settings: AudioSessionSettings) {
        let newSettings = _consolidatedSettings(settings)
        guard audioSession == nil || newSettings != currentSettings else { return }
        
        // Start the audio session.
        do {
            let session = audioSession ?? AVAudioSession.sharedInstance()
            try session.setCategory(newSettings.category.sessionValue,
                                    mode: newSettings.mode.sessionValue,
                                    options: newSettings.mixingOptions.sessionValue)
            currentSettings = newSettings
            if audioSession == nil {
                try session.setActive(true)
                audioSession = session
            }
        }
        catch let err {
            debugPrint("WARNING! Failed to start AV session. \(err)")
        }
    }
    
    private func _consolidatedSettings(_ prioritySettings: AudioSessionSettings) -> AudioSessionSettings {
        var settings: AudioSessionSettings = prioritySettings
        Set(activityMapping.values).forEach {
            settings.merge($0)
        }
        if backgroundAudioIdentifiers.count > 0 {
            settings.merge(.backgroundSilence)
        }
        return settings
    }
    
    /// Stop the audio session.
    /// - parameter activity: The activity that is done using the audio session.
    public func stopAudioSession(on activity: AudioSessionActivity) {
        backgroundAudioIdentifiers.remove(activity.identifier)
        activityMapping[activity.identifier] = nil
        orderedIdentifiers.removeAll(where: { $0 == activity.identifier })
        if let prioritySettings = _prioritySettings() {
            let newSettings = _consolidatedSettings(prioritySettings)
            if newSettings != currentSettings {
                do {
                    try audioSession?.setCategory(newSettings.category.sessionValue,
                                                  mode: newSettings.mode.sessionValue,
                                                  options: newSettings.mixingOptions.sessionValue)
                    currentSettings = newSettings
                } catch let err {
                    debugPrint("WARNING! Failed to update AV session settings. \(err)")
                }
            }
            if backgroundAudioIdentifiers.count > 0 {
                _startBackgroundSilenceIfNeeded()
            }
            else {
                silencePlayer?.stop()
                silencePlayer = nil
            }
        }
        else {
            silencePlayer?.stop()
            silencePlayer = nil
            audioSession = nil
            currentSettings = nil
            do {
                try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            } catch let err {
                debugPrint("WARNING! Failed to stop AV session. \(err)")
            }
        }
    }
    
    private func _prioritySettings() -> AudioSessionSettings? {
        if let previous = orderedIdentifiers.last,
           let prioritySettings = activityMapping[previous] {
            return prioritySettings
        }
        else if backgroundAudioIdentifiers.count > 0 {
            return .backgroundSilence
        }
        else {
            return nil
        }
    }
    
    private func _startBackgroundSilenceIfNeeded() {
        guard silencePlayer == nil,
              let settings = currentSettings,
              settings.category < .record,
              let player = SilencePlayer()
        else {
            return
        }
        player.play()
        silencePlayer = player
    }
}

extension AudioSessionSettings {
    static let backgroundSilence: AudioSessionSettings = AudioSessionSettings(category: .continuousPlayback,
                                                                                  mode: .spokenAudio,
                                                                                  mixingOptions: .mixWithOthers)
}

/// An audio player that plays the background sound used to keep the motion sensors active. This is
/// a work around to allow the task to continue running in the background without requiring GPS by
/// instead playing an audio file of silence.
///
/// - note: As of this writing, speech-to-text using the `AVSpeechSynthesizer` will *not* run in the
/// background after 5 seconds and turning on background audio using `AVAudioSession` is not enough
/// to keep any timers running. syoung 05/21/2019
///
fileprivate class SilencePlayer {

    let audioPlayer: AVAudioPlayer
    
    init?() {
        // Load the audio file.
        do {
            let bundle = Bundle.module
            let url = bundle.url(forResource: "Silence", withExtension: "wav")!
            self.audioPlayer = try AVAudioPlayer(contentsOf: url)
            self.audioPlayer.numberOfLoops = -1
            self.audioPlayer.prepareToPlay()
        } catch let error {
            debugPrint("Failed to open audio file. \(error)")
            return nil
        }
    }
    
    func play() {
        audioPlayer.play()
    }
    
    func stop() {
        guard audioPlayer.isPlaying else { return }
        audioPlayer.stop()
    }
}

extension AudioSessionSettings.Category {
    var sessionValue: AVAudioSession.Category {
        switch self {
        case .ambient:
            return .ambient
        case .soloAmbient:
            return .soloAmbient
        case .playAndRecord:
            return .playAndRecord
        case .intermittentPlayback, .continuousPlayback:
            return .playback
        case .record:
            return .record
        }
    }
}

extension AudioSessionSettings.Mode {
    var sessionValue: AVAudioSession.Mode {
        switch self {
        case .gameChat:
            return .gameChat
        case .measurement:
            return .measurement
        case .moviePlayback:
            return .moviePlayback
        case .spokenAudio:
            return .spokenAudio
        case .videoChat:
            return .videoChat
        case .videoRecording:
            return .videoRecording
        case .voiceChat:
            return .voiceChat
        case .voicePrompt:
            if #available(iOS 12.0, *) {
                return .voicePrompt
            } else {
                return .spokenAudio
            }
        case .default:
            return .default
        }
    }
}

extension AudioSessionSettings.MixingOptions {
    var sessionValue: AVAudioSession.CategoryOptions {
        switch self {
        case .mixWithOthers:
            return .mixWithOthers
        case .duckOthers:
            return .duckOthers
        case .interruptSpokenAudioAndMixWithOthers:
            return .interruptSpokenAudioAndMixWithOthers
        case .default:
            return []
        }
    }
}

#else

/// Applications that do not support audio sessions are currently not supported.
public final class AudioSessionController {
    public static let shared: AudioSessionController = AudioSessionController()

    public func startAudioSessionIfNeeded(on activity: AudioSessionActivity,
                                          with settings: AudioSessionSettings = AudioSessionSettings()) {
        // TODO: syoung 12/18/2020 Implement support when/if needed for these platforms.
        print("WARNING! Audio session support is not implemented for this platform.")
    }
    
    /// Stop the audio session.
    public func stopAudioSession(on activity: AudioSessionActivity) {
        // TODO: syoung 12/18/2020 Implement support when/if needed for these platforms.
        print("WARNING! Audio session support is not implemented for this platform.")
    }
}

#endif
