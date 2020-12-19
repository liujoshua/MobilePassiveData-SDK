//
//  AsyncActionStatus.swift
//  
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

/// `AsyncActionStatus` is an enum used to track the status of an `AsyncAction`.
@objc
public enum AsyncActionStatus : Int {
    
    /// Initial state before the controller has been started.
    case idle = 0
    
    /// Status if the controller is currently requesting authorization. Once in this state and
    /// until the controller is `starting`, the UI should be blocked from any view transitions.
    case requestingPermission
    
    /// Status if the controller has granted permission, but not yet been started.
    case permissionGranted
    
    /// The controller is starting up. This is the state once `AsyncAction.start()` has been
    /// called but before the recorder or request is running.
    case starting
    
    /// The action is running. For `RecorderConfiguration` controllers, this means that the
    /// recording is open. For `RequestConfiguration` controllers, this means that the request is
    /// in-flight.
    case running
    
    /// Waiting for in-flight buffers to be appended and ready to close.
    case waitingToStop
    
    /// Cleaning up by closing any buffers or file handles and processing any results that are
    /// returned by this controller.
    case processingResults
    
    /// Stopping any sensor managers. The controller should move to this state **after** any
    /// results are processed.
    /// - note: Once in this state, the async action should **not** be changing the results
    /// associated with this action.
    case stopping
    
    /// The controller is finished running and ready to `dealloc`.
    case finished
    
    /// The recorder or request was cancelled and any results may be invalid.
    case cancelled
    
    /// The recorder or request failed and any results may be invalid.
    case failed
}

extension AsyncActionStatus : Comparable {
    public static func <(lhs: AsyncActionStatus, rhs: AsyncActionStatus) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

extension AsyncActionStatus : CustomStringConvertible {
    public var description: String {
        switch self {
        case .idle:
            return "idle"
        case .requestingPermission:
            return "requestingPermission"
        case .permissionGranted:
            return "permissionGranted"
        case .starting:
            return "starting"
        case .running:
            return "running"
        case .waitingToStop:
            return "waitingToStop"
        case .processingResults:
            return "processingResults"
        case .stopping:
            return "stopping"
        case .finished:
            return "finished"
        case .cancelled:
            return "cancelled"
        case .failed:
            return "failed"
        }
    }
}
