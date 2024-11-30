//
//  Extensions.swift
//  DadJoke
//
//  Created by David Reed on 1/16/23.
//

import Foundation

extension DateFormatter {
  static let iso8601Full: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
    formatter.calendar = Calendar(identifier: .iso8601)
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    return formatter
  }()
}

enum FetchAndDecodeError: Error {
    case fetch(Error)
    case notHTTPURLResponse(URLResponse)
    case httpStatus(Int)
    case decode(Data, Error)
}

extension Decodable {

    static func decodeJSON(jsonData: Data, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy? = nil) throws -> Self {
        do {
            //            print(String(data: jsonData, encoding: .utf8)!)
            let decoder = JSONDecoder()
            if let dds = dateDecodingStrategy {
                decoder.dateDecodingStrategy = dds
            }
            let decoded = try decoder.decode(Self.self, from: jsonData)
            return decoded
        } catch {
            print(String(data: jsonData, encoding: .utf8)!)
            print(error)
            throw FetchAndDecodeError.decode(jsonData, error)
        }
    }

    /// fetches data from a URL rquest and decodes it as JSON for the type used
    ///
    /// can be used as DecodableTypeName.fetchAndDecodeJSON(urlRequest: request)
    ///
    /// - Parameter urlRequest: urlRequest to fetch from
    /// - Returns: an object of the type specified (or throws an error if fails)
    static func fetchAndDecodeJSON(urlRequest: URLRequest, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy? = nil) async throws -> Self {
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            guard let httpResponse = response as? HTTPURLResponse else {
                print(response)
                throw FetchAndDecodeError.notHTTPURLResponse(response)
            }
            guard httpResponse.statusCode == 200 else {
                print("fetch error, status code: ", httpResponse.statusCode)
                throw FetchAndDecodeError.httpStatus(httpResponse.statusCode)
            }
            return try Self.decodeJSON(jsonData: data, dateDecodingStrategy: dateDecodingStrategy)
        } catch {
            print(error)
            throw FetchAndDecodeError.fetch(error)
        }
    }
}
