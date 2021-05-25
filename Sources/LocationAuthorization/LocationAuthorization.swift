//
//  LocationAuthorization.swift
//
//  Copyright © 2018-2021 Sage Bionetworks. All rights reserved.
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
import CoreLocation
import MobilePassiveData

/// `LocationAuthorization` is a wrapper for the CoreLocation library that allows a general-purpose
/// step or task to query this library for authorization if and only if that library is required by
/// the application.
///
/// Before using this adaptor, the calling application or framework will need to register the
/// adaptor using `PermissionAuthorizationHandler.registerAdaptorIfNeeded()`.
///
/// You will need to add the privacy permission for location and motion sensors to the application
/// `Info.plist` file. As of this writing (syoung 02/08/2018), those keys are:
/// - `Privacy - Location Always and When In Use Usage Description`
/// - `Privacy - Location When In Use Usage Description`
public final class LocationAuthorization : NSObject, PermissionAuthorizationAdaptor, CLLocationManagerDelegate {
    
    enum LocationAuthorizationError : Error {
        case timeout
    }
    
    public static let shared = LocationAuthorization()
        
    public let permissions: [PermissionType] = [
        StandardPermissionType.location,
        StandardPermissionType.locationWhenInUse,
    ]

    /// Returns the authorization status for the location manager.
    public func authorizationStatus(for permission: String) -> PermissionAuthorizationStatus {
        _authStatus(for: permission).status
    }
    
    private func _authStatus(for permission: String) -> (status: PermissionAuthorizationStatus, permissionType: StandardPermissionType?) {
        guard let permissionType = StandardPermissionType(rawValue: permission),
              self.permissions.contains(where: { $0.identifier == permissionType.identifier })
            else {
                return (.notDetermined, nil)
        }
        return (Self.authorizationStatus(for: permissionType), permissionType)
    }
    
    /// Returns authorization status for `.location` and `.locationWhenInUse` permissions.
    public static func authorizationStatus(for permission: StandardPermissionType) -> PermissionAuthorizationStatus {
        switch permission {
        case .location:
            return _locationAuthorizationStatus(true)
        case .locationWhenInUse:
            return _locationAuthorizationStatus(false)
        default:
            return .notDetermined
        }
    }
    
    private static func _locationAuthorizationStatus(_ requiresBackground: Bool) -> PermissionAuthorizationStatus {
        _convertAuthStatus(CLLocationManager.authorizationStatus(), requiresBackground: requiresBackground)
    }
    
    private lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate = self
        return manager
    }()
    
    private var _completion: ((PermissionAuthorizationStatus, Error?) -> Void)?
    private var _requestingType: StandardPermissionType?
    
    /// Requests permission to access the device location.
    public func requestAuthorization(for permission: Permission, _ completion: @escaping ((PermissionAuthorizationStatus, Error?) -> Void)) {
        let (status, pType) = self._authStatus(for: permission.identifier)
        guard status == .notDetermined, let permissionType = pType else {
            completion(status, nil)
            return
        }
        
        _completion = completion
        _requestingType = permissionType
        switch permissionType {
        case .location:
            locationManager.requestAlwaysAuthorization()
        default:
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    private static func _convertAuthStatus(_ clAuthStatus: CLAuthorizationStatus, requiresBackground: Bool) -> PermissionAuthorizationStatus {
        switch clAuthStatus {
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .authorizedWhenInUse:
            return requiresBackground ? .denied : .authorized
        default:
            return .authorized
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard status != .notDetermined else { return }
        let rsdStatus = Self._convertAuthStatus(status, requiresBackground: _requestingType == .location )
        _completion?(rsdStatus, nil)
        _completion = nil
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        _completion?(.denied, error)
        _completion = nil
    }
}

