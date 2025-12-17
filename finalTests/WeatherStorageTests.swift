//
//  WeatherStorageTest.swift
//  final
//
//  Created by Baisal Kenesbek on 17.12.2025.
//

import XCTest
@testable import final

final class WeatherStorageTests: XCTestCase {
    private var defaults: UserDefaults!
    private var storage: WeatherStorage!

    override func setUp() {
        super.setUp()
        let suiteName = "WeatherStorageTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
        storage = WeatherStorage(defaults: defaults)
    }

    override func tearDown() {
        defaults = nil
        storage = nil
        super.tearDown()
    }

    func testToggleFavoriteAddsAndRemoves() {
        let city = City(name: "Almaty", country: "KZ", admin1: "Almaty", latitude: 43.2567, longitude: 76.9286)

        XCTAssertFalse(storage.isFavorite(city))
        storage.toggleFavorite(city)
        XCTAssertTrue(storage.isFavorite(city))

        storage.toggleFavorite(city)
        XCTAssertFalse(storage.isFavorite(city))
    }

    func testSettingsRoundTrip() {
        let settings = WeatherSettings(
            temperatureUnit: .fahrenheit,
            windSpeedUnit: .mph,
            showWind: false,
            forecastDays: 5
        )

        storage.saveSettings(settings)
        XCTAssertEqual(storage.loadSettings(), settings)
    }

    func testNotesSaveAndLoad() {
        let city = City(name: "Astana", country: "KZ", admin1: nil, latitude: 51.1694, longitude: 71.4491)

        XCTAssertEqual(storage.loadNote(for: city.id), "")
        storage.saveNote("Bring jacket", for: city.id)
        XCTAssertEqual(storage.loadNote(for: city.id), "Bring jacket")
    }
}
