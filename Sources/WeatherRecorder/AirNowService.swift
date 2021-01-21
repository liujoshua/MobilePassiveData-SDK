//
//  AirNowService.swift
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
import CoreLocation

public class AirNowService : WeatherService {

    public let configuration: WeatherServiceConfiguration
    
    init(configuration: WeatherServiceConfiguration) {
        self.configuration = configuration
    }
        
    public func fetchResult(for coordinates: CLLocation, _ completion: @escaping WeatherServiceCompletionHandler) {
        let dateString = ISO8601DateOnlyFormatter.string(from: Date())
        let url = URL(string: "https://www.airnowapi.org/aq/forecast/latLong/?format=application/json&latitude=\(coordinates.coordinate.latitude)&longitude=\(coordinates.coordinate.longitude)&date=\(dateString)&distance=25&API_KEY=\(configuration.apiKey)")!
        let task = URLSession.shared.dataTask(with: url) { [weak self] (data, _, error) in
            self?.processResponse(url, dateString, data, error, completion)
        }
        task.resume()
    }
    
    private func processResponse(_ url: URL, _ dateString: String, _ data: Data?, _ error: Error?, _ completion: @escaping WeatherServiceCompletionHandler) {
        guard error == nil, let json = data else {
            completion(self, nil, error)
            return
        }
        do {
            let decoder = JSONDecoder()
            let responses = try decoder.decode([ResponseObject].self, from: json)
            guard let responseObject = responses.first(where: { $0.dateForecast.trimmingCharacters(in: .whitespaces) == dateString }) else {
                print("WARNING! Failed to find valid response from \(self.configuration.providerName): dateString=\(dateString)\n\(responses)")
                let err = ValidationError.unexpectedNullObject("No valid dateForecast was returned.")
                completion(self, nil, err)
                return
            }
            let result = AirQualityServiceResult(identifier: configuration.identifier,
                                                 providerName: .airNow,
                                                 aqi: responseObject.aqi,
                                                 category: responseObject.category?.copyTo())
            completion(self, [result], nil)
        }
        catch let err {
            let jsonString = String(data: json, encoding: .utf8)
            print("WARNING! \(configuration.providerName) service response decoding failed.\n\(url)\n\(String(describing: jsonString))\n")
            completion(self, nil, err)
        }
    }
    
    private struct ResponseObject : Codable {
        private enum CodingKeys : String, CodingKey {
            case dateIssue = "DateIssue", dateForecast = "DateForecast", stateCode = "StateCode", aqi = "AQI", category = "Category"
        }
        let dateIssue: String
        let dateForecast: String
        let stateCode: String?
        let aqi: Int?
        let category: Category?
        
        struct Category : Codable {
            private enum CodingKeys : String, CodingKey {
                case number = "Number", name = "Name"
            }
            let number: Int
            let name: String
            
            func copyTo() -> AirQualityServiceResult.Category {
                .init(number: self.number, name: self.name)
            }
        }
    }
}

fileprivate let exampleResponse =
    """
    [{"DateIssue":"2020-11-20 ","DateForecast":"2020-11-20 ","ReportingArea":"Yuba City/Marysville","StateCode":"CA","Latitude":39.1389,"Longitude":-121.6175,"ParameterName":"PM2.5","AQI":46,"Category":{"Number":1,"Name":"Good"},"ActionDay":false,"Discussion":"Friday through Sunday, a weak upper-level ridge of high pressure over northern California will reduce vertical mixing in Yuba and Sutter Counties. In addition, light northwesterly winds will limit pollutant dispersion. These conditions will cause AQI levels to increase from high-Good Friday to Moderate over the weekend."},
    {"DateIssue":"2020-11-20 ","DateForecast":"2020-11-21 ","ReportingArea":"Yuba City/Marysville","StateCode":"CA","Latitude":39.1389,"Longitude":-121.6175,"ParameterName":"PM2.5","AQI":57,"Category":{"Number":2,"Name":"Moderate"},"ActionDay":false,"Discussion":"Friday through Sunday, a weak upper-level ridge of high pressure over northern California will reduce vertical mixing in Yuba and Sutter Counties. In addition, light northwesterly winds will limit pollutant dispersion. These conditions will cause AQI levels to increase from high-Good Friday to Moderate over the weekend."},
    {"DateIssue":"2020-11-20 ","DateForecast":"2020-11-22 ","ReportingArea":"Yuba City/Marysville","StateCode":"CA","Latitude":39.1389,"Longitude":-121.6175,"ParameterName":"PM2.5","AQI":66,"Category":{"Number":2,"Name":"Moderate"},"ActionDay":false,"Discussion":"Friday through Sunday, a weak upper-level ridge of high pressure over northern California will reduce vertical mixing in Yuba and Sutter Counties. In addition, light northwesterly winds will limit pollutant dispersion. These conditions will cause AQI levels to increase from high-Good Friday to Moderate over the weekend."}]
    """
