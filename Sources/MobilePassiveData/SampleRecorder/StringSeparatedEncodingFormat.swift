//
//  StringSeparatedEncodingFormat.swift
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
import JsonModel

/// A protocol that can be used to define the keys and header to use in a string-separated file.
/// - seealso: `RecordSampleLogger`
public protocol StringSeparatedEncodingFormat {
    
    /// The string to use as the separator. For example, a comma-delimited file uses a "," character.
    var encodingSeparator: String { get }
    
    /// The content type for the file.
    var contentType: String { get }
    
    /// The file extension for this file type.
    var fileExtension: String { get }
    
    /// A string that includes a header for the file. The columns in the table should be separated
    /// using the `encodingSeparator`.
    func fileTableHeader() -> String
    
    /// A list of the coding keys to use to build the delimited string for a single Element in an
    /// Array.
    func codingKeys() -> [CodingKey]
}

/// Implementation of the `StringSeparatedEncodingFormat` protocol that wraps a comma separated
/// encodable.
public struct CSVEncodingFormat<K> : StringSeparatedEncodingFormat where K : DelimiterSeparatedEncodable {
    public typealias Key = K
    
    /// Does this encoding format include a header?
    public var includesHeader: Bool = true
    
    /// Returns a comma.
    public var encodingSeparator: String {
        return ","
    }
    
    /// Returns "text/csv".
    public var contentType: String {
        return "text/csv"
    }
    
    /// Returns "csv".
    public var fileExtension: String {
        return "csv"
    }
    
    public func fileTableHeader() -> String {
        return includesHeader ? Key.fileTableHeader(with: encodingSeparator) : ""
    }
    
    public func codingKeys() -> [CodingKey] {
        return Key.codingKeys()
    }
    
    public init() {
    }
}

/// A special-case encodable that can be encoded to a comma-delimited string.
///
/// A csv-formatted file is a smaller format that might be suitable for saving data to a file that will
/// be parsed into a table, **but** the elements must all conform to single value container encoding
/// **and** they may not include any strings in the encoded value.
public protocol DelimiterSeparatedEncodable : Encodable {
    
    /// An ordered list of coding keys to use when encoding this object to a comma-separated string.
    static func codingKeys() -> [CodingKey]
}

extension DelimiterSeparatedEncodable {
    
    /// The comma-separated list of header strings to use as the header in a CSV file.
    public static func fileTableHeader(with delimiter: String) -> String {
        return self.codingKeys().map { $0.stringValue }.joined(separator: delimiter)
    }
    
    /// The comma-separated string representing this object.
    public func delimiterEncodedString(with delimiter: String, factory: SerializationFactory = SerializationFactory.defaultFactory) throws -> String {
        return try delimiterEncodedString(with: type(of: self).codingKeys(), delimiter: delimiter, factory: factory)
    }
}

extension Encodable {
    
    /// Returns the comma-separated string representing this object.
    /// - parameter codingKeys: The codingKeys to use as mask for the comma-delimited list.
    func delimiterEncodedString(with codingKeys: [CodingKey], delimiter: String, factory: SerializationFactory = SerializationFactory.defaultFactory) throws -> String {
        let dictionary = try self.jsonEncodedDictionary(using: factory)
        let values: [String] = try codingKeys.map { (key) -> String in
            guard let value = dictionary[key.stringValue] else { return "" }
            if ((value is [JsonSerializable]) || (value is [String : JsonSerializable])) {
                let context = EncodingError.Context(codingPath: [], debugDescription: "A comma-delimited string encoding cannot encode a nested array or dictionary.")
                throw EncodingError.invalidValue(value, context)
            }
            let string = "\(value)"
            if string.contains(delimiter) {
                let context = EncodingError.Context(codingPath: [], debugDescription: "A delimited string encoding cannot encode a string that contains the delimiter: '\(delimiter)'.")
                throw EncodingError.invalidValue(string, context)
            }
            return string
        }
        return values.joined(separator: delimiter)
    }
}
