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
        static let selectedCity = "weather.selected.city.v1"
        static let customTitles = "weather.customTitles.v1"
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
        loadFavorites().contains(where: { $0.id == city.id })
    }

    func toggleFavorite(_ city: City) {
        var favorites = loadFavorites()
        if let idx = favorites.firstIndex(where: { $0.id == city.id }) {
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

    func loadSelectedCity() -> City? {
        guard let data = defaults.data(forKey: Keys.selectedCity) else { return nil }
        return try? decoder.decode(City.self, from: data)
    }

    func saveSelectedCity(_ city: City?) {
        guard let city else {
            defaults.removeObject(forKey: Keys.selectedCity)
            return
        }
        guard let data = try? encoder.encode(city) else { return }
        defaults.set(data, forKey: Keys.selectedCity)
    }

    func loadCustomTitle(for cityID: String) -> String {
        let titles = defaults.dictionary(forKey: Keys.customTitles) as? [String: String] ?? [:]
        return titles[cityID] ?? ""
    }

    func saveCustomTitle(_ title: String, for cityID: String) {
        var titles = defaults.dictionary(forKey: Keys.customTitles) as? [String: String] ?? [:]
        titles[cityID] = title
        defaults.set(titles, forKey: Keys.customTitles)
    }

    func displayTitle(for city: City) -> String {
        let custom = loadCustomTitle(for: city.id).trimmingCharacters(in: .whitespacesAndNewlines)
        return custom.isEmpty ? city.name : custom
    }
}
