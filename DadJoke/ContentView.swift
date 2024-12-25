//
//  ContentView.swift
//  DadJoke
//
//  Created by David Reed on 1/14/23.
//

import SwiftUI
import FetchJSON

@Observable
@MainActor
final class JokeModel {
    var jokes: [Joke] = []
    @ObservationIgnored var existingIDs: Set<String> = []

    func addNewJoke(jokeID: String = "") {
        Task {
            guard let request = jokeID.isEmpty ? Joke.urlRequest(for: .random) : Joke.urlRequest(for: .byID(jokeID)) else { return }
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
                    }
                }
            }
        }
    }

    private func fetchJokeByID(jokeID: String = "EYo4TCAdUf") async -> Joke? {
        guard let request = Joke.urlRequest(for: .byID(jokeID)) else {
            fatalError()
        }
        return await fetchJoke(request: request)
    }

    private func fetchJoke(searchTerm: String) async -> [Joke] {
        let searchConfig = JokeSearchConfig(searchTerm: searchTerm)
        guard let request = JokeSearch.urlRequest(for: searchConfig) else {
            return []
        }
        // print(request.url!)
        do {
            let jokes = try await JokeSearch.fetchAndDecode(urlRequest: request)
            return jokes.results
        } catch  {
            print(error.localizedDescription)
        }
        return []
    }

    private func fetchJoke(request: URLRequest) async -> Joke? {
        do {
            let joke = try await Joke.fetchAndDecode(urlRequest: request)
            return joke
        } catch {
            print(error.localizedDescription)
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
    @State private var model = JokeModel()

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
                model.addNewJoke(searchTerm: "windows")
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
