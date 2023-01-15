//
//  ContentView.swift
//  DadJoke
//
//  Created by David Reed on 1/14/23.
//

import SwiftUI

@MainActor
final class JokeModel: ObservableObject {
    @Published var jokes: [Joke] = []
    var existingIDs: Set<String> = []

    func addNewJoke(jokeID: String = "") {
        Task {
            let request = jokeID.isEmpty ? Joke.request : Joke.request(jokeID: jokeID)
            while (true) {
                if let joke = await fetchJoke(request: request) {
                    if !existingIDs.contains(joke.id) {
                        addJoke(joke)
                        break
                    }
                } else {
                    print("error trying to fetch joke")
                    break
                }
            }
        }
    }

    func addNewJoke(searchTerm: String) {
        Task {
            let jokes = await fetchJoke(searchTerm: searchTerm)
            if jokes.isEmpty {
                addNewJoke()
            } else {
                for joke in jokes.reversed() {
                    if !existingIDs.contains(joke.id) {
                        addJoke(joke)
                        break
                    }
                }
            }
        }
    }

    private func fetchJokeByID(jokeID: String = "EYo4TCAdUf") async -> Joke? {
        let request = Joke.request(jokeID: jokeID)
        return await fetchJoke(request: request)
    }

    private func fetchJoke(searchTerm: String) async -> [Joke] {
        let request = SearchJokes.request(searchTerm: searchTerm)
        do {
            let jokes = try await SearchJokes.fetchAndDecodeJSON(urlRequest: request)
            return jokes.results
        } catch FetchAndDecodeError.notHTTPURLReponse(let urlResponse) {
            print("response error", urlResponse)
        } catch FetchAndDecodeError.httpStatus(let status) {
            print("status error code", status)
        } catch FetchAndDecodeError.decode(let data, let error) {
            print("decoding error")
            if let s = String(data: data, encoding: .utf8) {
                print(s)
            } else {
                print(data)
            }
            print(error)
        } catch {
            print("other fetch error")
        }
        return []
    }

    private func fetchJoke(request: URLRequest) async -> Joke? {
        do {
            let joke = try await Joke.fetchAndDecodeJSON(urlRequest: request)
            return joke
        } catch FetchAndDecodeError.notHTTPURLReponse(let urlResponse) {
            print("response error", urlResponse)
        } catch FetchAndDecodeError.httpStatus(let status) {
            print("status error code", status)
        } catch FetchAndDecodeError.decode(let data, let error) {
            print("decoding error")
            if let s = String(data: data, encoding: .utf8) {
                print(s)
            } else {
                print(data)
            }
            print(error)
        } catch {
            print("other fetch error")
        }
        return nil
    }

    private func addJoke(_ joke: Joke) {
        withAnimation {
            jokes.insert(joke, at: 0)
            existingIDs.insert(joke.id)
        }
    }

    var hasJokes: Bool { !jokes.isEmpty }

    func removeJokes(at offsets: IndexSet) {
        jokes.remove(atOffsets: offsets)
    }
}

struct ContentView: View {
    @StateObject private var model = JokeModel()

    var body: some View {
        NavigationStack {
            List {
                ForEach(model.jokes) { joke in
                    NavigationLink(joke.setup()) {
                        // fire and forget navigation to a view with the full joke
                        VStack {
                            Text(joke.joke)
                            Spacer()
                            Text(joke.id)
                            Spacer()
                        }
                        .padding()
                    }
                }
                .onDelete(perform: deleteJokes)
            }
            // for pull to refresh
            .refreshable {
                model.addNewJoke()
            }
            .navigationTitle("Dad Jokes")
            .toolbar {
                Button {
                    model.addNewJoke()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        // runs once when a view appears
        .task() {
            // make certain at least one joke
            if !model.hasJokes {
                model.addNewJoke(searchTerm: "computer")
//                model.addNewJoke(jokeID: "ozPmbFtWDlb")
            }
        }
    }

    func deleteJokes(at offfsets: IndexSet) {
        model.removeJokes(at: offfsets)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
