//
//  AudioSessionSettings.swift
//  
//
//  Copyright © 2021 Sage Bionetworks. All rights reserved.
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
import JsonModel


/// The settings required for a given activity's audio session.
public struct AudioSessionSettings : Codable, Hashable {
    private enum CodingKeys : String, CodingKey, CaseIterable {
        case category, mode, mixingOptions
    }
    
    public fileprivate(set) var category: Category
    public fileprivate(set) var mode: Mode
    public fileprivate(set) var mixingOptions: MixingOptions
    
    public init(category: Category = .soloAmbient,
                mode: Mode = .default,
                mixingOptions: MixingOptions = .default) {
        self.category = category
        self.mode = mode
        self.mixingOptions = mixingOptions
    }
    
    mutating func merge(_ otherSettings: AudioSessionSettings) {
        if self.category < otherSettings.category {
            if otherSettings.category == .record && self.category.isPlayback {
                self.category = .playAndRecord
            } else {
                self.category = otherSettings.category
            }
        }
        if self.mixingOptions < otherSettings.mixingOptions {
            self.mixingOptions = otherSettings.mixingOptions
        }
    }
    
    /// By default, any audio played isn't required and the assessment or data requested can be
    /// collected without it.
    public static let `default` = AudioSessionSettings()
    
    /// Used for cases where the voice prompts run while this audio session is active should duck
    /// other audio. This will speak the voice prompts played by the action *even if* the
    /// participant has their silencer on.
    ///
    /// - note: If an app requires background audio, the app developer needs to add this capability.
    public static let voicePrompt = AudioSessionSettings(category: .intermittentPlayback,
                                                         mode: .voicePrompt,
                                                         mixingOptions: .duckOthers)
    
    /// Used for cases where the voice prompts run while this audio session is active, music playing
    /// should be mixed (quieter while speaking) and voice audio should be interupted. This is
    /// used by an activity where you want the participant's music to play while the activity is
    /// running but also allow voice prompts to be played even if the app is in the background.
    /// This will speak the voice prompts played by the action *even if* the participant has their
    /// silencer on.
    ///
    /// - note: The app developer needs to add the background audio capability.
    public static let backgroundVoicePrompt = AudioSessionSettings(category: .continuousPlayback,
                                                                   mode: .voicePrompt,
                                                                   mixingOptions: .interruptSpokenAudioAndMixWithOthers)
    
    /// Used to indicate that DB-level is being measured.
    /// - note: This requires adding the microphone privacy permission to the app.
    public static let recordDBLevel = AudioSessionSettings(category: .record,
                                                           mode: .measurement,
                                                           mixingOptions: .default)
    
    /// Platform-agnostic mapping to the `AVAudioSession.Category`.
    public enum Category : String, Codable, CaseIterable, Comparable {
        /// The category for an app in which sound playback is nonprimary—that is, your app also
        /// works with the sound turned off. If a user switches from your app to another audio app,
        /// your app audio will be silenced, even if the other app uses a mixable category.
        case ambient
        /// The main difference with the Ambient category is that when the audio session is
        /// activated, audio from other apps is interrupted. This category is recommended for apps
        /// which use audio that should not be mixed with other audio apps running in the
        /// background.
        case soloAmbient
        /// The category for playing intermittent sounds, either using pre-recorded sound files or
        /// using speech-to-text, that are central to the successful use of your app. As such, the
        /// app will play sound *even if* the user has the silence lock on.
        case intermittentPlayback
        /// The category for playing music or other sounds continuously that are central to the
        /// successful use of your app. As such, the app will play sound *even if* the user has the
        /// silence lock on.
        case continuousPlayback
        /// The category for recording audio; this category silences playback audio.
        case record
        /// The category for recording (input) and playback (output) of audio, such as for a Voice
        /// over Internet Protocol (VoIP) app.
        case playAndRecord
        
        var isPlayback: Bool {
            self == .intermittentPlayback || self == .continuousPlayback
        }
        
        public static func < (lhs: AudioSessionSettings.Category, rhs: AudioSessionSettings.Category) -> Bool {
            Category.allCases.firstIndex(of: lhs)! < Category.allCases.firstIndex(of: rhs)!
        }
    }
    
    /// Platform-agnostic mapping to the `AVAudioSession.Mode`.
    public enum Mode : String, Codable, CaseIterable {
        /// The default audio session mode.
        case `default`
        /// A mode that the GameKit framework sets on behalf of an application that uses GameKit’s
        /// voice chat service.
        case gameChat
        /// A mode that indicates that your app is performing measurement of audio input or output.
        case measurement
        /// A mode that indicates that your app is playing back movie content.
        case moviePlayback
        /// A mode used for continuous spoken audio to pause the audio when another app plays a
        /// short audio prompt.
        case spokenAudio
        /// A mode that indicates that your app is engaging in online video conferencing.
        case videoChat
        /// A mode that indicates that your app is recording a movie.
        case videoRecording
        /// A mode that indicates that your app is performing two-way voice communication, such as
        /// using Voice over Internet Protocol (VoIP).
        case voiceChat
        /// A mode that indicates that your app plays audio using text-to-speech.
        case voicePrompt
    }
    
    /// Platform-agnostic mapping to a subset of the `AVAudioSession.CategoryOptions`.
    public enum MixingOptions : String, Codable, CaseIterable, Comparable {
        /// Use the `Category` and `Mode` to determine the most appropriate mixing options.
        case `default`
        /// An option that indicates whether audio from this session mixes with audio from active
        /// sessions in other audio apps.
        case mixWithOthers
        /// An option that determines whether to pause spoken audio content from other sessions
        /// when your app plays its audio.
        case interruptSpokenAudioAndMixWithOthers
        /// An option that reduces the volume of other audio session while audio from this session
        /// plays.
        case duckOthers
        
        public static func < (lhs: AudioSessionSettings.MixingOptions, rhs: AudioSessionSettings.MixingOptions) -> Bool {
            MixingOptions.allCases.firstIndex(of: lhs)! < MixingOptions.allCases.firstIndex(of: rhs)!
        }
    }
}

extension AudioSessionSettings.Category : StringEnumSet, DocumentableStringEnum {
}

extension AudioSessionSettings.Mode : StringEnumSet, DocumentableStringEnum {
}

extension AudioSessionSettings.MixingOptions : StringEnumSet, DocumentableStringEnum {
}

extension AudioSessionSettings : DocumentableStruct {

    public static func codingKeys() -> [CodingKey] {
        CodingKeys.allCases
    }
    
    public static func isRequired(_ codingKey: CodingKey) -> Bool {
        true
    }
    
    public static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? CodingKeys else {
            throw DocumentableError.invalidCodingKey(codingKey, "\(codingKey) is not recognized for this class")
        }
        switch key {
        case .category:
            return .init(propertyType: .reference(Category.documentableType()))
        case .mode:
            return .init(propertyType: .reference(Mode.documentableType()))
        case .mixingOptions:
            return .init(propertyType: .reference(MixingOptions.documentableType()))
        }
    }
    
    public static func examples() -> [AudioSessionSettings] {
        [
            AudioSessionSettings(),
            .backgroundVoicePrompt,
            .recordDBLevel,
            .voicePrompt,
        ]
    }
}
