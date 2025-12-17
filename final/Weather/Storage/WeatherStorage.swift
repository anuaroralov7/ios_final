//
//  WeatherStorage.swift
//  final
//
//  Created by Baisal Kenesbek on 17.12.2025.
//

import Foundation

final class WeatherStorage {
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    private enum Keys {
        static let favorites = "weather.favorites.cities.v1"
        static let settings = "weather.settings.v1"
        static let notes = "weather.notes.v1"
    }

    func loadFavorites() -> [City] {
        guard let data = defaults.data(forKey: Keys.favorites) else { return [] }
        return (try? decoder.decode([City].self, from: data)) ?? []
    }

    func saveFavorites(_ cities: [City]) {
        guard let data = try? encoder.encode(cities) else { return }
        defaults.set(data, forKey: Keys.favorites)
    }

    func isFavorite(_ city: City) -> Bool {
        loadFavorites().contains(city)
    }

    func toggleFavorite(_ city: City) {
        var favorites = loadFavorites()
        if let idx = favorites.firstIndex(of: city) {
            favorites.remove(at: idx)
        } else {
            favorites.append(city)
        }
        saveFavorites(favorites)
    }

    func loadSettings() -> WeatherSettings {
        guard let data = defaults.data(forKey: Keys.settings) else { return .default }
        return (try? decoder.decode(WeatherSettings.self, from: data)) ?? .default
    }

    func saveSettings(_ settings: WeatherSettings) {
        guard let data = try? encoder.encode(settings) else { return }
        defaults.set(data, forKey: Keys.settings)
    }

    func loadNote(for cityID: String) -> String {
        let notes = defaults.dictionary(forKey: Keys.notes) as? [String: String] ?? [:]
        return notes[cityID] ?? ""
    }

    func saveNote(_ note: String, for cityID: String) {
        var notes = defaults.dictionary(forKey: Keys.notes) as? [String: String] ?? [:]
        notes[cityID] = note
        defaults.set(notes, forKey: Keys.notes)
    }
}
