//
//  Joke.swift
//  DadJoke
//
//  Created by David Reed on 1/14/23.
//

import Foundation

struct Joke: Identifiable, Equatable, Hashable, Codable {
    var id: String
    var joke: String

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

    static var urlComponents: URLComponents {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "icanhazdadjoke.com"
        return components
    }

    static var request: URLRequest {
        let components = Joke.urlComponents
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        // specify the header for JSON format of the joke
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    static func request(jokeID: String) -> URLRequest {
        var components = Joke.urlComponents
        components.path = "/j/\(jokeID)"

        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"

        // specify the header for JSON format of the joke
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }
}

struct SearchJokes: Codable {
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

    static func request(searchTerm: String) -> URLRequest {
        var components = Joke.urlComponents
        components.path = "/search"
        components.queryItems = [
            URLQueryItem(name: "term", value: searchTerm)
        ]
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"

        // specify the header for JSON format of the joke
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }
}
