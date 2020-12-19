//
//  WeatherResult.swift
//  
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
import JsonModel
import MobilePassiveData

extension SerializableResultType {
    public static let weather: SerializableResultType = "weather"
}

/// A `WeatherResult` includes results for both weather and air quality in a consolidated result.
/// Because this result must be mutable, it is defined as a class.
public class WeatherResult : SerializableResultData {
    private enum CodingKeys : String, CodingKey, CaseIterable {
        case identifier, serializableResultType = "type", startDate, endDate, weather, airQuality
    }
    public private(set) var serializableResultType: SerializableResultType = .weather

    public let identifier: String
    public var startDate: Date = Date()
    public var endDate: Date = Date()
    public var weather: WeatherServiceResult?
    public var airQuality: AirQualityServiceResult?
    
    init(identifier: String) {
        self.identifier = identifier
    }
}

public struct WeatherServiceResult : Codable, Equatable {
    private enum CodingKeys : String, CodingKey, CaseIterable {
        case serviceType = "type", identifier, providerName, startDate,
             temperature, seaLevelPressure, groundLevelPressure, humidity, clouds, rain, snow, wind
    }
    public private(set) var serviceType: WeatherServiceType = .weather

    public let identifier: String
    public let providerName: WeatherServiceProviderName
    public var startDate: Date
    
    /// Current average temperature. Unit: Celsius
    public let temperature: Double?
    
    /// Atmospheric pressure at sea level. Unit: hPa
    public let seaLevelPressure: Double?
    
    /// Atmospheric pressure at ground level. Unit: hPa
    public let groundLevelPressure: Double?
    
    /// % Humidity.
    public let humidity: Double?
    
    /// % Cloudiness.
    public let clouds: Double?
    
    /// Recent rainfall.
    public let rain: Precipitation?
    
    /// Recent snowfall.
    public let snow: Precipitation?
    
    /// Current wind conditions.
    public let wind: Wind?
    
    public struct Precipitation: Codable, Equatable {
        /// Amount of precipitation in the past hour.
        public let pastHour: Double?
        /// Amount of precipitation in the past three hours.
        public let pastThreeHours: Double?
    }

    public struct Wind : Codable, Equatable {
        /// Wind speed. Unit: meter/sec
        public let speed: Double
        /// Wind direction, degrees (meteorological)
        public let degrees: Double?
        /// Wind gust. Unit: meter/sec
        public let gust: Double?
    }
}

extension WeatherServiceResult : SerializableResultData {
    public var serializableResultType: SerializableResultType {
        .init(rawValue: self.serviceType.rawValue)
    }
    
    public var endDate: Date {
        get { startDate }
        set { }
    }
}

public struct AirQualityServiceResult : Codable, Equatable {
    private enum CodingKeys : String, CodingKey, CaseIterable {
        case serviceType = "type", identifier, providerName, startDate, aqi, category
    }
    public private(set) var serviceType: WeatherServiceType = .airQuality
    
    public let identifier: String
    public let providerName: WeatherServiceProviderName
    public var startDate: Date = Date()
    public let aqi: Int?
    public let category: Category?

    public struct Category : Codable, Equatable {
        public let number: Int
        public let name: String
    }
}

extension AirQualityServiceResult : SerializableResultData {
    public var serializableResultType: SerializableResultType {
        .init(rawValue: serviceType.rawValue)
    }

    public var endDate: Date {
        get { startDate }
        set {} // ignored
    }
}
