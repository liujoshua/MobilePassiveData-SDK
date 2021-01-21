//
//  WeatherRecorder.swift
//
//  Copyright © 2020-2021 Sage Bionetworks. All rights reserved.
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
import JsonModel

public typealias WeatherServiceCompletionHandler = (WeatherService, [ResultData]?, Error?) -> Void

public protocol WeatherService : class {
    var configuration: WeatherServiceConfiguration { get }
    func fetchResult(for coordinates: CLLocation, _ completion: @escaping WeatherServiceCompletionHandler)
}

/// `WeatherRecorder` is used to ping the participant's location in the background and use that to
/// query weather and air quality services.
open class WeatherRecorder : NSObject, AsyncActionController, CLLocationManagerDelegate {

    public let weatherConfiguration: WeatherConfiguration

    public init(_ config: WeatherConfiguration) {
        self.weatherConfiguration = config
        self.weatherResult = WeatherResult(identifier: config.identifier)
        super.init()
    }
    
    /// The delegate used for a callback when the location service fails.
    public weak var delegate: AsyncActionControllerDelegate?
    
    /// The location manager is used to ping the particpant's current location.
    public private(set) var locationManager: CLLocationManager?
    
    /// The weather result associated with this recorder.
    public private(set) var weatherResult: WeatherResult

    /// Override to request GPS and motion permissions.
    public func requestPermissions(on viewController: Any, _ completion: @escaping AsyncActionCompletionHandler) {
        
        // Get the current status and exit early if the status is restricted or denied.
        let status = CLLocationManager.authorizationStatus()
        if status == .denied || status == .restricted {
            let status: PermissionAuthorizationStatus = (status == .restricted) ? .restricted : .denied
            _serviceFailed(status: status)
            completion(self, nil, self.error)
            return
        }
        
        // If the status is not determined, then need to request it.
        self._setupLocationManager()
        if status == .notDetermined {
            self.status = .requestingPermission
            self._permissionCompletion = completion
            #if os(macOS)
            self.locationManager!.requestAlwaysAuthorization()
            #else
            self.locationManager!.requestWhenInUseAuthorization()
            #endif
        }
        else {
            self.status = .permissionGranted
            completion(self, nil, nil)
        }
    }
    
    private var _permissionCompletion: AsyncActionCompletionHandler?
    private var _startCompletion: AsyncActionCompletionHandler?
    
    private func _setupLocationManager() {
        guard self.locationManager == nil else { return }
        
        // setup the location manager when asking for permissions
        let manager = CLLocationManager()
        manager.delegate = self
        #if os(iOS)
        manager.allowsBackgroundLocationUpdates = false
        manager.pausesLocationUpdatesAutomatically = false
        #endif
        self.locationManager = manager
    }
    
    private func _serviceFailed(status: PermissionAuthorizationStatus) {
        guard self.status < .running else { return }
        self.error = PermissionError.notAuthorized(StandardPermission.location, status)
        self.status = .failed
    }
    
    public func start(_ completion: AsyncActionCompletionHandler?) {
        guard self.status < .starting else { return }
        if self.status <= .requestingPermission {
            self.status = .starting
            self._startCompletion = completion
            return
        }
        else {
            _requestLocation(completion)
        }
    }
    
    private func _requestLocation(_ completion: AsyncActionCompletionHandler?) {
        guard self.status < .running else { return }
        let status = CLLocationManager.authorizationStatus()
        #if os(macOS)
        let granted = status == .authorizedAlways
        #else
        let granted = status == .authorizedAlways || status == .authorizedWhenInUse
        #endif
        guard granted else {
            _serviceFailed(status: .denied)
            DispatchQueue.main.async {
                completion?(self, nil, self.error)
            }
            return
        }
        DispatchQueue.main.async {
            guard self.status < .running else { return }
            self._setupLocationManager()
            self.status = .running
            self.locationManager?.requestLocation()
            completion?(self, nil, nil)
        }
    }
    
    private func _stopLocationUpdates() {
        guard let manager = self.locationManager else { return }
        manager.stopUpdatingLocation()
        self.locationManager = nil
    }

    public func stop(_ completion: AsyncActionCompletionHandler?) {
        DispatchQueue.main.async {
            self._stopLocationUpdates()
            self.status = .finished
            completion?(self, self.weatherResult, self.error)
        }
    }
    
    public func cancel() {
        DispatchQueue.main.async {
            self._stopLocationUpdates()
            self.status = .cancelled
        }
    }
    
    // MARK: AsyncActionController wrapper properties and methods
    
    @objc dynamic public private(set) var status: AsyncActionStatus = .idle
    
    public var configuration: AsyncActionConfiguration { weatherConfiguration }
    
    public var isPaused: Bool { false }
    
    public private(set) var error: Error?
    
    open var result: ResultData? { weatherResult }
    
    public func pause() {
        // ignored
    }
    
    public func resume() {
        // ignored
    }
    
    public func moveTo(stepPath: String) {
        // ignored
    }
    
    // MARK: CLLocationManagerDelegate
    
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard self.status <= .running else { return }
        let status = CLLocationManager.authorizationStatus()
        guard status != .notDetermined else { return }
        if status == .denied || status == .restricted {
            let status: PermissionAuthorizationStatus = (status == .restricted) ? .restricted : .denied
            _serviceFailed(status: status)
        }
        else if self.status <= .requestingPermission {
            self.status = .permissionGranted
        }
        self._permissionCompletion?(self, nil, self.error)
        self._permissionCompletion = nil
        
        if self.status == .starting {
            self._requestLocation(_startCompletion)
            self._startCompletion = nil
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // Implement the deprecated method b/c older OS versions.
        self.locationManagerDidChangeAuthorization(manager)
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard self.status <= .running else { return }
        // Once the location is updated we don't need a pointer to the manager.
        guard let currentLocation = locations.last else { return }
        self.locationManager = nil
        self.queryWeatherServices(for: currentLocation)
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard self.status <= .running else { return }
        self.error = error
        self.status = .failed
        self.delegate?.asyncAction(self, didFailWith: error)
        debugPrint("WARNING! Location services did fail. \(error)")
    }
    
    // MARK: Weather services management
    
    open func instantiateService(for config: WeatherServiceConfiguration) -> WeatherService? {
        config.instantiateDefaultService()
    }
    
    /// Used to keep the instantiated services from deallocating before completion.
    private var services: [String: WeatherService] = [:]
    
    func queryWeatherServices(for location: CLLocation) {
        weatherConfiguration.services.forEach { (config) in
            guard services[config.identifier] == nil,
                let service = self.instantiateService(for: config)
            else {
                return
            }
            services[config.identifier] = service
            service.fetchResult(for: location) { [weak self] (service, results, error) in
                guard let strongSelf = self else { return }
                strongSelf.services[config.identifier] = nil
                guard error == nil, let results = results else {
                    print("WARNING! Weather service failed. \(service.configuration.providerName): \(String(describing: error))")
                    return
                }
                self?.processServiceResults(results)
            }
        }
    }
    
    func processServiceResults(_ results: [ResultData]) {
        guard self.status <= .running else { return }
        results.forEach { (result) in
            switch result {
            case let airQuality as AirQualityServiceResult:
                self.weatherResult.airQuality = airQuality
            case let weather as WeatherServiceResult:
                self.weatherResult.weather = weather
            default:
                print("WARNING! \(result) ignored by WeatherRecorder.")
            }
        }
    }
}

