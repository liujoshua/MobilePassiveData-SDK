//
//  OpenWeatherService.swift
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
import MobilePassiveData
import JsonModel
import CoreLocation


public class OpenWeatherService : WeatherService {

    public let configuration: WeatherServiceConfiguration
    
    init(configuration: WeatherServiceConfiguration) {
        self.configuration = configuration
    }
    
    public func fetchResult(for coordinates: CLLocation, _ completion: @escaping WeatherServiceCompletionHandler) {
        let url = URL(string: "https://api.openweathermap.org/data/2.5/weather?lat=\(coordinates.coordinate.latitude)&lon=\(coordinates.coordinate.longitude)&units=metric&appid=\(configuration.apiKey)")!
        let task = URLSession.shared.dataTask(with: url) { [weak self] (data, _, error) in
            self?.processResponse(url, data, error, completion)
        }
        task.resume()
    }
    
    func processResponse(_ url: URL, _ data: Data?, _ error: Error?, _ completion: @escaping WeatherServiceCompletionHandler) {
        guard error == nil, let json = data else {
            completion(self, nil, error)
            return
        }
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            let responseObject = try decoder.decode(ResponseObject.self, from: json)
            let result = responseObject.copyTo(with: configuration.identifier)
            completion(self, [result], nil)
        }
        catch let err {
            let jsonString = String(data: json, encoding: .utf8)
            print("WARNING! \(configuration.providerName) service response decoding failed.\n\(url)\n\(String(describing: jsonString))\n")
            completion(self, nil, err)
        }
    }
    
    private struct ResponseObject : Codable {
        let main: Main
        let wind: Wind?
        let clouds: Clouds?
        let rain: Precipitation?
        let snow: Precipitation?
        let dt: Date

        struct Main : Codable {
            // Temperature. Unit: Celsius
            let temp: Double?
            // Temperature. This temperature parameter accounts for the human perception of weather. Unit: Celsius
            let feels_like: Double?
            // Minimum temperature at the moment. This is minimal currently observed temperature (within large megalopolises and urban areas). Unit: Celsius
            let temp_min: Double?
            // Maximum temperature at the moment. This is maximal currently observed temperature (within large megalopolises and urban areas). Unit: Celsius
            let temp_max: Double?
            // Atmospheric pressure (on the sea level, if there is no sea_level or grnd_level data), hPa
            let pressure: Double?
            // Atmospheric pressure on the sea level, hPa
            let sea_level: Double?
            // Atmospheric pressure on the ground level, hPa
            let grnd_level: Double?
            // Humidity, %
            let humidity: Double?
            
            func seaLevel() -> Double? {
                sea_level ?? ((grnd_level == nil) ? pressure : nil)
            }
        }
        
        struct Wind : Codable {
            // Wind speed. Unit: meter/sec
            let speed: Double?
            // Wind direction, degrees (meteorological)
            let deg: Double?
            // Wind gust. Unit Default: meter/sec
            let gust: Double?
            
            func copyTo() -> WeatherServiceResult.Wind? {
                (self.speed != nil) ? .init(speed: speed!, degrees: deg, gust: gust) : nil
            }
        }
        
        struct Clouds : Codable {
            // Cloudiness, %
            let all: Double
        }
        
        struct Precipitation: Codable {
            private enum CodingKeys: String, CodingKey {
                case pastHour = "1hr", pastThreeHours = "3hr"
            }
            let pastHour: Double?
            let pastThreeHours: Double?
            
            func copyTo() -> WeatherServiceResult.Precipitation {
                .init(pastHour: pastHour, pastThreeHours: pastThreeHours)
            }
        }
        
        func copyTo(with identifier: String) -> WeatherServiceResult {
            WeatherServiceResult(identifier: identifier,
                                 providerName: .openWeather,
                                 startDate: dt,
                                 temperature: self.main.temp,
                                 seaLevelPressure: self.main.seaLevel(),
                                 groundLevelPressure: self.main.grnd_level,
                                 humidity: self.main.humidity,
                                 clouds: self.clouds?.all,
                                 rain: self.rain?.copyTo(),
                                 snow: self.snow?.copyTo(),
                                 wind: self.wind?.copyTo())
        }
    }
}

fileprivate let exampleResponse =
    """
    {
      "coord": {
        "lon": -122.08,
        "lat": 37.39
      },
      "weather": [
        {
          "id": 800,
          "main": "Clear",
          "description": "clear sky",
          "icon": "01d"
        }
      ],
      "base": "stations",
      "main": {
        "temp": 282.55,
        "feels_like": 281.86,
        "temp_min": 280.37,
        "temp_max": 284.26,
        "pressure": 1023,
        "humidity": 100
      },
      "visibility": 16093,
      "wind": {
        "speed": 1.5,
        "deg": 350
      },
      "clouds": {
        "all": 1
      },
      "dt": 1560350645,
      "sys": {
        "type": 1,
        "id": 5122,
        "message": 0.0139,
        "country": "US",
        "sunrise": 1560343627,
        "sunset": 1560396563
      },
      "timezone": -25200,
      "id": 420006353,
      "name": "Mountain View",
      "cod": 200
      }
    """

