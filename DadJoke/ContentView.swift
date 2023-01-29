//
//  ContentView.swift
//  DadJoke
//
//  Created by David Reed on 1/14/23.
//

import SwiftUI
import Boutique

extension Store where Item == Joke {
    static let favoriteJokesStore = Store<Joke>(storage: SQLiteStorageEngine.default(appendingPath: "Favorites"))
}

@MainActor
final class JokeModel: ObservableObject {
    @Published var jokes: [Joke] = []
    @Stored(in: .favoriteJokesStore) var favoritesStore: [Joke]

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

struct JokeDetailView: View {
    @ObservedObject var model: JokeModel
    @Binding var joke: Joke

    var body: some View {
        VStack {
            Text(joke.joke)
                .padding(.bottom, 24)
            Button {
                toggleFavorite()
            } label: {
                Group {
                    if joke.isFavorite {
                        Label("Unfavorite", systemImage: "heart.fill")
                    } else {
                        Label("Favorite", systemImage: "heart.slash")
                    }
                }
                .foregroundColor(.red)
            }
            .padding(.bottom, 48)
            Text(joke.id)
            Spacer()
        }
        .padding()
    }

    func toggleFavorite() {
        joke.isFavorite.toggle()
        Task {
            do {
                if joke.isFavorite {
                    try await model.$favoritesStore.insert(joke)
                } else {
                    try await model.$favoritesStore.remove(joke)
                }
            } catch {
                if joke.isFavorite {
                    print("error marking favorite", error)
                } else {
                    print("error removing from favorites", error)
                }
            }
        }
    }
}

struct JokeView: View {
    @ObservedObject var model: JokeModel

    var body: some View {
        NavigationStack {
            List {
                ForEach($model.jokes) { $joke in
                    NavigationLink(joke.setup()) {
                        // fire and forget navigation to a view with the full joke
                        JokeDetailView(model: model, joke: $joke)
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

struct FavoriteJokesView: View {
    @ObservedObject var model: JokeModel
    @State private var favoriteJokes: [Joke] = []

    var body: some View {
        List {
            ForEach(favoriteJokes) { joke in
                Text("\(joke.joke)")
            }
            .onDelete(perform: deleteFavorites)
        }
        .onReceive(model.$favoritesStore.$items, perform: { jokes in
            favoriteJokes = jokes
        })
        .task {
            favoriteJokes = model.favoritesStore
        }
    }

    func deleteFavorites(at offfsets: IndexSet) {
        for index in offfsets.reversed() {
            let joke = favoriteJokes[index]
            // need to update in list of all jokes also
            if let index = model.jokes.firstIndex(where: { $0.id == joke.id } ) {
                model.jokes[index].isFavorite = false
            }
            Task {
                do {
                    try await model.$favoritesStore.remove(joke)
                } catch {}
            }
        }
    }
}

struct ContentView: View {
    @StateObject private var model = JokeModel()

    var body: some View {
        TabView {
            JokeView(model: model)
                .tabItem {
                    Label("Jokes", systemImage: "network")
                }
            FavoriteJokesView(model: model)
                .tabItem {
                    Label("Favorites", systemImage: "heart.fill")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
