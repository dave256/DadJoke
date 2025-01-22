//
//  ContentView.swift
//  DadJoke
//
//  Created by David Reed on 1/14/23.
//

import FetchJSON
import SwiftUI

@Observable
@MainActor
final class JokeModel {
    var jokes: [Joke] = []
    @ObservationIgnored var existingIDs: Set<String> = []

    func addNewJoke(jokeID: String = "") {
        Task {
            let request: JokeRequest
            if !jokeID.isEmpty {
                request = JokeRequest.id(jokeID)
            } else {
                request = JokeRequest.random
            }
            while true {
                do {
                    let jokes = try await request.fetch()
                    if let joke = jokes.first {
                        if !existingIDs.contains(joke.id) {
                            addJoke(joke)
                            break
                        } else if !jokeID.isEmpty {
                            break
                        }
                    }
                } catch {
                    print(error)
                    break
                }
            }
        }
    }

    func addNewJoke(searchTerm: String) {
        Task {
            let request = JokeRequest.search(searchTerm)
            do {
                let jokes = try await request.fetch()
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
                            Text(joke.jok)
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
        .task {
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
