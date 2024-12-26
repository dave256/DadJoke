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
        let trimmedJoke = joke.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: .punctuationCharacters)
        // now look for last occurence of one of these characters hoping that is where the setup ends
        let setupSeparator: Array<Character> = ["?", ".", "!", ":", ";", "-", "-", ","]
        // check in order so we can prioritize certain characters as being most likely to end the setup
        for ch in setupSeparator {
            // if find one return up to that as the setup
            if let index = trimmedJoke.lastIndex(of: ch) {
                return String(joke[...index])
            }
        }

        // if didn't find any punctuation, look for the word but and return setup as up to but not including "but"
        if let range = joke.range(of: "but", options: [.backwards, .caseInsensitive]) {
            return String(joke[..<range.lowerBound])
        }

        // default to returning the entire joke if couldn't find one
        return joke
    }
}

struct JokeConfig: URLQueryConfig {
    static var baseComponents: URLComponents {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "icanhazdadjoke.com"
        return components
    }

    static var headers: [String: String] {
        [
            "Accept": "application/json",
        ]
    }

    enum RequestType {
        case random
        case byID(String)
    }
    var requestType: RequestType

    func path() -> String {
        switch requestType {
            case .random:
                return "/"
            case .byID(let id):
                return "/j/\(id)"
        }
    }

    var queryItems: [URLQueryItem] = []

    static func randomRequest() -> URLRequest? {
        let config: JokeConfig = .init(requestType: .random)
        return config
            .urlRequest(components: JokeConfig.baseComponents, headers: JokeConfig.headers)
    }

    static func byIDRequest(id: String) -> URLRequest? {
        let config: JokeConfig = .init(requestType: .byID(id))
        return config
            .urlRequest(components: JokeConfig.baseComponents, headers: JokeConfig.headers)
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

struct JokeSearchConfig: URLQueryConfig {
    var searchTerm: String?
    var page: Int?
    var limit: Int?

    func path() -> String {
        "/search"
    }

    var queryItems: [URLQueryItem] {
        var items: [String: LosslessStringConvertible] = [:]
        if let searchTerm { items["term"] = searchTerm }
        if let page { items["page"] = page }
        if let limit { items["limit"] = limit }
        let queryItems: [URLQueryItem] = .init(items)
        return queryItems
    }

    static var headers: [String: String] {
        [
            "Accept": "application/json",
        ]
    }

    static func searchRequest(search: String? = nil, page: Int? = nil, limit: Int? = nil) -> URLRequest? {
        let config: JokeSearchConfig = .init(searchTerm: search, page: page, limit: limit)
        return config
            .urlRequest(components: JokeConfig.baseComponents, headers: JokeConfig.headers)
    }

}

extension JokeSearchConfig {
    init(searchTerm: String) {
        self.init(searchTerm: searchTerm, page: nil, limit: nil)
    }
}
