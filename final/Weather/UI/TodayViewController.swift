import UIKit

final class TodayViewController: UIViewController {
    @IBOutlet private weak var cityLabel: UILabel!
    @IBOutlet private weak var tempLabel: UILabel!
    @IBOutlet private weak var detailsLabel: UILabel!
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var refreshButton: UIButton!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!

    private let api = WeatherServices.api
    private let storage = WeatherServices.storage

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Today"
        iconImageView.tintColor = .systemBlue
        activityIndicator.hidesWhenStopped = true
        refresh()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refresh()
    }

    @IBAction private func refreshTapped(_ sender: UIButton) {
        refresh()
    }

    private func refresh() {
        guard let city = storage.loadSelectedCity() ?? storage.loadFavorites().first else {
            cityLabel.text = "Select a city in Forecast"
            tempLabel.text = "—"
            detailsLabel.text = ""
            iconImageView.image = UIImage(systemName: "location.magnifyingglass")
            return
        }

        cityLabel.text = storage.displayTitle(for: city)
        tempLabel.text = "Loading…"
        detailsLabel.text = ""
        iconImageView.image = UIImage(systemName: "cloud")

        activityIndicator.startAnimating()
        Task { @MainActor in
            defer { activityIndicator.stopAnimating() }
            do {
                let settings = storage.loadSettings()
                let forecast = try await api.fetchForecast(
                    latitude: city.latitude,
                    longitude: city.longitude,
                    temperatureUnit: settings.apiTemperatureUnit,
                    windSpeedUnit: settings.apiWindSpeedUnit,
                    forecastDays: settings.apiForecastDays
                )
                apply(forecast: forecast, city: city, settings: settings)
            } catch {
                showError(error)
            }
        }
    }

    @MainActor
    private func apply(forecast: OpenMeteoForecastResponse, city: City, settings: WeatherSettings) {
        let temp = forecast.current?.temperature2m
        let code = forecast.current?.weatherCode
        let wind = forecast.current?.windSpeed10m

        cityLabel.text = city.name
        tempLabel.text = formatTemp(temp, unit: settings.temperatureUnit)

        var parts: [String] = []
        if let code {
            parts.append(WeatherCode.iconAndText(for: code).text)
            iconImageView.image = UIImage(systemName: WeatherCode.iconAndText(for: code).symbol)
        } else {
            iconImageView.image = UIImage(systemName: "cloud")
        }

        if settings.showWind, let wind {
            parts.append("Wind \(formatWind(wind, unit: settings.windSpeedUnit))")
        }
        detailsLabel.text = parts.joined(separator: " • ")
    }

    private func formatTemp(_ value: Double?, unit: TemperatureUnit) -> String {
        guard let value else { return "—" }
        let rounded = Int(value.rounded())
        return unit == .celsius ? "\(rounded)°C" : "\(rounded)°F"
    }

    private func formatWind(_ value: Double, unit: WindSpeedUnit) -> String {
        let rounded = Int(value.rounded())
        switch unit {
        case .kmh: return "\(rounded) km/h"
        case .ms: return "\(rounded) m/s"
        case .mph: return "\(rounded) mph"
        case .kn: return "\(rounded) kn"
        }
    }

    @MainActor
    private func showError(_ error: Error) {
        let alert = UIAlertController(title: "Network error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
