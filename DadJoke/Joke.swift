//
//  Joke.swift
//  DadJoke
//
//  Created by David Reed on 1/14/23.
//

import FetchJSON
import Foundation

struct Joke: Identifiable, Hashable, Codable {
    var id: String
    var joke: String
}

extension Joke {
    func setup() -> String {
        // first get rid of any whitespace at end and then any punctuation characters at the end
        let trimmedJoke = joke.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: .punctuationCharacters)
        // now look for last occurence of one of these characters hoping that is where the setup ends
        let setupSeparator: [Character] = [
            "?", ".", "!", ":", ";", "-", "-", ",",
        ]
        // check in order so we can prioritize certain characters as being most likely to end the setup
        for ch in setupSeparator {
            // if find one return up to that as the setup
            if let index = trimmedJoke.lastIndex(of: ch) {
                return String(joke[...index])
            }
        }

        // if didn't find any punctuation, look for the word but and return setup as up to but not including "but"
        if let range = joke.range(
            of: "but", options: [.backwards, .caseInsensitive])
        {
            return String(joke[..<range.lowerBound])
        }

        // default to returning the entire joke if couldn't find one
        return joke
    }

    static func request(_ requestType: JokeRequest) -> URLRequest? {
        requestType.request
    }

}

enum JokeRequest: URLQueryConfig {
    case random
    case id(String)
    case search(String?, page: Int? = nil, limit: Int? = nil)

    static var baseComponents: URLComponents {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "icanhazdadjoke.com"
        return components
    }

    static var headers: [String: String] {
        [
            "Accept": "application/json"
        ]
    }

    func path() -> String {
        switch self {
        case .random:
            "/"
        case .id(let id):
            "/j/\(id)"
        case .search(_, _, _):
            "/search"
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case .random, .id(_):
            return []
        case .search(let searchTerm, let page, let limit):
            var items: [String: LosslessStringConvertible] = [:]
            if let searchTerm { items["term"] = searchTerm }
            if let page { items["page"] = page }
            if let limit { items["limit"] = limit }
            let queryItems: [URLQueryItem] = .init(items)
            return queryItems
        }
    }

    var request: URLRequest? {
        self.urlRequest(
            components: Self.baseComponents, headers: Self.headers)
    }

    func fetch() async throws -> [Joke] {
        switch self {
        case .random, .id(_):
            if let request = request {
                let joke = try await Joke.fetchAndDecode(urlRequest: request)
                return [joke]
            } else {
                return []
            }
        case .search(_, _, _):
            if let request = request {
                let jokes = try await JokeSearch.fetchAndDecode(urlRequest: request)
                return jokes.results
            } else {
                return []
            }
        }
    }
}

public struct JokeSearch: Codable {
    let status: Int
    let limit: Int
    let results: [Joke]
    let nextPage: Int
    let previousPage: Int
    let totalPages: Int
    let totalJokes: Int
    let searchTerm: String
    let currentPage: Int

    enum CodingKeys: String, CodingKey {
        case nextPage = "next_page"
        case previousPage = "previous_page"
        case totalPages = "total_pages"
        case totalJokes = "total_jokes"
        case searchTerm = "search_term"
        case currentPage = "current_page"
        case status
        case limit
        case results
    }
}
