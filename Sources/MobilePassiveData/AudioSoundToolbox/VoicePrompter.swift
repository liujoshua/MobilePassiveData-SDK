//
//  VoicePrompter.swift
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

#if canImport(AVFoundation)
import AVFoundation
#endif

#if canImport(UIKit)
import UIKit
#endif

/// A completion handler for the voice box.
public typealias VoicePrompterCompletionHandler = (_ text: String, _ finished: Bool) -> Void

/// `VoicePrompter` is used to "speak" text strings.
public protocol VoicePrompter {
    
    /// Is the voice box currently speaking?
    var isSpeaking: Bool { get }
    
    /// Command the voice box to speak the given text.
    /// - parameters:
    ///     - text: The text to speak.
    ///     - completion: The completion handler to call after the text has finished.
    func speak(text: String, completion: VoicePrompterCompletionHandler?)
    
    /// Command the voice box to stop speaking.
    func stopTalking()
}

#if canImport(AVFoundation)

/// `TextToSpeechSynthesizer` is a concrete implementation of the `VoicePrompter` protocol that
/// uses the `AVSpeechSynthesizer` to synthesize text to sound.
public final class TextToSpeechSynthesizer : NSObject, VoicePrompter {
    
    /// The language code to use for the speech voice.
    public var languageCode: String
    
    /// A specific identifier for the `AVSpeechSynthesisVoice` to use.
    public var voiceIdentifier: String?
    
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    private var _completionHandlers: [String: VoicePrompterCompletionHandler] = [:]
    
    public override init(languageCode: String = AVSpeechSynthesisVoice.currentLanguageCode()) {
        self.languageCode = languageCode
        super.init()
        self.speechSynthesizer.delegate = self
        self.speechSynthesizer.usesApplicationAudioSession = true
        
        // TODO: FIXME syoung 02/05/2021 in iOS 14.3, the enhanced voice which is default for the
        // US is broken so this is a work-around for that bug.
        self.voiceIdentifier = (languageCode == "en-US") ? "com.apple.ttsbundle.siri_female_en-US_compact" : nil
    }
    
    deinit {
        speechSynthesizer.stopSpeaking(at: .immediate)
        speechSynthesizer.delegate = nil
    }
    
    /// Is the voice box currently speaking? The default implementation will return `true` if the
    /// `AVSpeechSynthesizer` is speaking.
    public var isSpeaking: Bool {
        return speechSynthesizer.isSpeaking
    }

    /// Command the voice box to speak the given text. The default implementation will create an
    /// `AVSpeechUtterance` and call the speech synthesizer with the utterance.
    ///
    /// - parameters:
    ///     - text: The text to speak.
    ///     - completion: The completion handler to call after the text has finished.
    public func speak(text: String, completion: VoicePrompterCompletionHandler?) {
        if speechSynthesizer.isSpeaking {
            stopTalking()
        }
        
        #if canImport(UIKit) && !os(watchOS)
        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: text)
        }
        #endif
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
    
        if let voiceId = self.voiceIdentifier, let voice = AVSpeechSynthesisVoice(identifier: voiceId) {
            utterance.voice = voice
        }
        else {
            utterance.voice = AVSpeechSynthesisVoice(language: self.languageCode)
        }
        
        _completionHandlers[text] = completion
        
        speechSynthesizer.speak(utterance)
    }

    /// Command the voice box to stop speaking.
    public func stopTalking() {
        speechSynthesizer.stopSpeaking(at: .word)
    }
}

extension TextToSpeechSynthesizer : AVSpeechSynthesizerDelegate {
    
    /// Called when the text is synthesizer is finished.
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        guard let handler = _completionHandlers[utterance.speechString] else { return }
        _completionHandlers[utterance.speechString] = nil
        handler(utterance.speechString, true)
    }
    
    /// Called when the text is synthesizer is cancelled.
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        guard let handler = _completionHandlers[utterance.speechString] else { return }
        _completionHandlers[utterance.speechString] = nil
        handler(utterance.speechString, false)
    }
}

#else

// TODO: syoung 12/18/2020 Support Text-to-Voice for platforms that do not support AVFoundation.
public final class TextToSpeechSynthesizer : NSObject, VoicePrompter {
    var isSpeaking: Bool { false }
    func speak(text: String, completion: VoiceBoxCompletionHandler?) {
        print("WARNING! VoiceBox is not supported on this platform.")
        completion?(text, false)
    }
    func stopTalking() {}
}

#endif


