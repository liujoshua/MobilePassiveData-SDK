//
//  AudioRecorderTests.swift
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
@testable import AudioRecorder

import JsonModel
import MobilePassiveData
import SharedResourcesTests

class AudioRecorderTests: XCTestCase {
    
    var decoder: JSONDecoder {
        return SerializationFactory.defaultFactory.createJSONDecoder()
    }
    
    var encoder: JSONEncoder {
        return SerializationFactory.defaultFactory.createJSONEncoder()
    }
    
    override func setUp() {
        super.setUp()

        // Use a statically defined timezone.
        ISO8601TimestampFormatter.timeZone = TimeZone(secondsFromGMT: Int(-2.5 * 60 * 60))
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testAudioLevelRecord_Coding() {
        let filename = "microphone_levels_record"
        guard let url = Bundle.testResources.url(forResource: filename, withExtension: "json")
        else {
            XCTFail("Could not find resource in the `Bundle.testResources`: \(filename).json")
            return
        }
        
        do {
            let json = try Data(contentsOf: url)
            let object = try decoder.decode(AudioLevelRecord.self, from: json)
            
            XCTAssertEqual(-41.02, object.average ?? 0, accuracy: 0.01)
            XCTAssertEqual(-35.46, object.peak ?? 0, accuracy: 0.01)
            XCTAssertEqual(1, object.timeInterval ?? 0, accuracy: 0.01)
            XCTAssertEqual(1.90, object.timestamp ?? 0, accuracy: 0.01)
            XCTAssertEqual(356541.29, object.uptime ?? 0, accuracy: 0.01)
            XCTAssertEqual("dbFS", object.unit)
            XCTAssertEqual("Dimensional Change Card Sort", object.stepPath)
            
            let jsonData = try encoder.encode(object)
            guard let dictionary = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String : Any]
                else {
                    XCTFail("Encoded object is not a dictionary")
                    return
            }
            
            XCTAssertEqual(-41.02, dictionary["average"] as? Double ?? 0, accuracy: 0.01)
            XCTAssertEqual(-35.46, dictionary["peak"] as? Double ?? 0, accuracy: 0.01)
            XCTAssertEqual(1, dictionary["timeInterval"] as? Double ?? 0, accuracy: 0.01)
            XCTAssertEqual(1.90, dictionary["timestamp"] as? Double ?? 0, accuracy: 0.01)
            XCTAssertEqual(356541.29, dictionary["uptime"] as? Double ?? 0, accuracy: 0.01)
            XCTAssertEqual("dbFS", dictionary["unit"] as? String)
            XCTAssertEqual("Dimensional Change Card Sort", dictionary["stepPath"] as? String)
            
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
}
