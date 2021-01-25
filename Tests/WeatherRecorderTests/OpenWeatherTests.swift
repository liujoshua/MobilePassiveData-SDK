//
//  OpenWeatherTests.swift
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

import XCTest
@testable import WeatherRecorder
import JsonModel
import MobilePassiveData
import SharedResourcesTests


class OpenWeatherTests: XCTestCase {
    
    var service: OpenWeatherService = {
        OpenWeatherService(configuration: WeatherServiceConfigurationObject(identifier: "weather", providerName: .openWeather, apiKey: "09458538-8403-419b-8600-9b541914e187"))
    }()
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testResponse() {
        let filename = "OpenWeather_Response"
        guard let url = Bundle.testResources.url(forResource: filename, withExtension: "json")
        else {
            XCTFail("Could not find resource in the `Bundle.testResources`: \(filename).json")
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let date = DateComponents(calendar: .init(identifier: .iso8601),
                                      timeZone: TimeZone.init(identifier: "America/Los_Angeles"),
                                      era: nil,
                                      year: 2021,
                                      month: 01,
                                      day: 22,
                                      hour: 14,
                                      minute: 40,
                                      second: 13).date!
            print(date)
            service.processResponse(url, data, nil) { (_, results, err) in
                XCTAssertNil(err)
                guard let result = results?.first as? WeatherServiceResult else {
                    XCTFail("Failed to return expected result for \(String(describing: results))")
                    return
                }
                
                XCTAssertEqual("weather", result.identifier)
                XCTAssertEqual(.weather, result.serviceType)
                XCTAssertEqual(.openWeather, result.providerName)
                XCTAssertEqual(date, result.startDate)
                XCTAssertEqual(279.53, result.temperature)
                XCTAssertEqual(1019, result.seaLevelPressure)
                XCTAssertNil(result.groundLevelPressure)
                XCTAssertEqual(result.humidity, 57)
                XCTAssertEqual(result.clouds, 0)
                XCTAssertNil(result.rain)
                XCTAssertNil(result.snow)
                XCTAssertEqual(.init(speed: 5.36, degrees: 297, gust: 9.39), result.wind)

            }
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
}
