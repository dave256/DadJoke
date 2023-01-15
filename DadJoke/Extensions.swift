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
    case notHTTPURLReponse(URLResponse)
    case httpStatus(Int)
    case decode(Data, Error)
}

extension Decodable {

    /// fetches data from a URL rquest and decodes it as JSON for the type used
    ///
    /// can be used as Joke.fetchAndDecodeJSON(urlRequest: request)
    ///
    /// - Parameter urlRequest: urlRequest to fetch from
    /// - Returns: an object of the type specified (or throws an error if fails)
    static func fetchAndDecodeJSON(urlRequest: URLRequest, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy? = nil) async throws -> Self {
        var jsonData: Data
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    print("fetch error, status code: ", httpResponse.statusCode)
                    throw FetchAndDecodeError.httpStatus(httpResponse.statusCode)
                }
            } else {
                print(response)
                throw FetchAndDecodeError.notHTTPURLReponse(response)
            }

            jsonData = data
        } catch {
            print(error)
            throw FetchAndDecodeError.fetch(error)
        }
        do {
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
}
