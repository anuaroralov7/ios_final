import UIKit
import CoreLocation

final class TodayViewController: UIViewController {
    @IBOutlet private weak var cityLabel: UILabel!
    @IBOutlet private weak var tempLabel: UILabel!
    @IBOutlet private weak var detailsLabel: UILabel!
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var forecastStackView: UIStackView!

    private let api = WeatherServices.api
    private let storage = WeatherServices.storage
    private let location = LocationService.shared

    private let defaultCity = City(
        name: "Almaty",
        country: "KZ",
        admin1: "Almaty",
        latitude: 43.2567,
        longitude: 76.9286
    )

    private var skeletonConfigured = false
    private let shimmerCity = ShimmerView()
    private let shimmerIcon = ShimmerView()
    private let shimmerTemp = ShimmerView()
    private let shimmerDetailsContainer = UIView()
    private let shimmerDetails1 = ShimmerView()
    private let shimmerDetails2 = ShimmerView()

    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = .current
        df.timeZone = .current
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()

    private let weekdayFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = .current
        df.timeZone = .current
        df.dateFormat = "EEEE"
        return df
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Today"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always

        view.backgroundColor = .systemGroupedBackground
        iconImageView.tintColor = .systemBlue
        iconImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 44, weight: .semibold)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.isHidden = true

        let refreshItem = UIBarButtonItem(image: UIImage(systemName: "arrow.clockwise"), style: .plain, target: self, action: #selector(refreshBarTapped))
        navigationItem.rightBarButtonItem = refreshItem

        configureTopSkeletonOverlayIfNeeded()

        refresh()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        configureTopSkeletonOverlayIfNeeded()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refresh()
    }

    @objc private func refreshBarTapped() {
        refresh()
    }

    private func refresh() {
        let settings = storage.loadSettings()
        setLoadingUI(true, placeholderCards: min(4, settings.apiForecastDays))
        location.requestLocation { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async {
                self.handleLocationResult(result)
            }
        }
    }

    @MainActor
    private func handleLocationResult(_ result: Result<CLLocation, Error>) {
        switch result {
        case .failure:
            let city = storage.loadSelectedCity() ?? defaultCity
            loadForecastForCity(city)
        case .success(let location):
            Task { @MainActor in
                await loadForecastForCoordinates(location.coordinate)
            }
        }
    }

    @MainActor
    private func loadForecastForCity(_ city: City) {
        Task { @MainActor in
            do {
                let settings = storage.loadSettings()
                let forecast = try await api.fetchForecast(
                    latitude: city.latitude,
                    longitude: city.longitude,
                    temperatureUnit: settings.apiTemperatureUnit,
                    windSpeedUnit: settings.apiWindSpeedUnit,
                    forecastDays: settings.apiForecastDays
                )
                apply(forecast: forecast, cityName: storage.displayTitle(for: city), settings: settings)
                setLoadingUI(false, placeholderCards: 0)
            } catch {
                setLoadingUI(false, placeholderCards: 0)
                showError(error)
            }
        }
    }

    @MainActor
    private func loadForecastForCoordinates(_ coord: CLLocationCoordinate2D) async {
        do {
            let settings = storage.loadSettings()
            let forecast = try await api.fetchForecast(
                latitude: coord.latitude,
                longitude: coord.longitude,
                temperatureUnit: settings.apiTemperatureUnit,
                windSpeedUnit: settings.apiWindSpeedUnit,
                forecastDays: settings.apiForecastDays
            )
            let name = await reverseGeocodeName(coord) ?? "Current location"
            apply(forecast: forecast, cityName: name, settings: settings)
            setLoadingUI(false, placeholderCards: 0)
        } catch {
            setLoadingUI(false, placeholderCards: 0)
            showError(error)
        }
    }

    private func reverseGeocodeName(_ coord: CLLocationCoordinate2D) async -> String? {
        await withCheckedContinuation { cont in
            CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: coord.latitude, longitude: coord.longitude)) { placemarks, _ in
                let pm = placemarks?.first
                cont.resume(returning: pm?.locality ?? pm?.administrativeArea ?? pm?.country)
            }
        }
    }

    @MainActor
    private func apply(forecast: OpenMeteoForecastResponse, cityName: String, settings: WeatherSettings) {
        let temp = forecast.current?.temperature2m
        let code = forecast.current?.weatherCode
        let wind = forecast.current?.windSpeed10m

        cityLabel.text = cityName
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

        applyDailyForecast(forecast, settings: settings)
    }

    @MainActor
    private func applyDailyForecast(_ forecast: OpenMeteoForecastResponse, settings: WeatherSettings) {
        forecastStackView.arrangedSubviews.forEach { v in
            forecastStackView.removeArrangedSubview(v)
            v.removeFromSuperview()
        }

        guard let daily = forecast.daily else { return }
        let count = min(daily.time.count, settings.apiForecastDays)

        for i in 0..<count {
            let dateString = daily.time[i]
            let date = dateFormatter.date(from: dateString)
            let title: String
            if let date {
                if Calendar.current.isDateInToday(date) { title = "Today" }
                else if Calendar.current.isDateInTomorrow(date) { title = "Tomorrow" }
                else { title = weekdayFormatter.string(from: date) }
            } else {
                title = dateString
            }

            let maxTemp = daily.temperature2mMax?[safe: i]
            let minTemp = daily.temperature2mMin?[safe: i]
            let subtitle = "\(formatTemp(minTemp, unit: settings.temperatureUnit)) • \(formatTemp(maxTemp, unit: settings.temperatureUnit))"

            let code = daily.weatherCode?[safe: i] ?? 3
            let symbol = WeatherCode.iconAndText(for: code).symbol

            forecastStackView.addArrangedSubview(makeForecastCard(title: title, subtitle: subtitle, symbol: symbol))
        }
    }

    private func makeForecastCard(title: String, subtitle: String, symbol: String) -> UIView {
        let container = UIView()
        container.backgroundColor = .secondarySystemGroupedBackground
        container.layer.cornerRadius = 12
        container.layer.masksToBounds = true

        let h = UIStackView()
        h.axis = .horizontal
        h.alignment = .center
        h.spacing = 12
        h.translatesAutoresizingMaskIntoConstraints = false

        let icon = UIImageView(image: UIImage(systemName: symbol))
        icon.tintColor = .systemBlue
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 28),
            icon.heightAnchor.constraint(equalToConstant: 28)
        ])

        let v = UIStackView()
        v.axis = .vertical
        v.spacing = 2
        v.alignment = .leading

        let titleLabel = UILabel()
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.text = title

        let subLabel = UILabel()
        subLabel.font = .preferredFont(forTextStyle: .subheadline)
        subLabel.textColor = .secondaryLabel
        subLabel.text = subtitle

        v.addArrangedSubview(titleLabel)
        v.addArrangedSubview(subLabel)

        h.addArrangedSubview(icon)
        h.addArrangedSubview(v)

        container.addSubview(h)
        NSLayoutConstraint.activate([
            h.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            h.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            h.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
            h.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -10),
            container.heightAnchor.constraint(greaterThanOrEqualToConstant: 54)
        ])

        return container
    }

    @MainActor
    private func setLoadingUI(_ isLoading: Bool, placeholderCards: Int) {
        navigationItem.rightBarButtonItem?.isEnabled = !isLoading
        setTopSkeleton(isLoading)

        if isLoading {
            forecastStackView.arrangedSubviews.forEach { v in
                forecastStackView.removeArrangedSubview(v)
                v.removeFromSuperview()
            }
            for _ in 0..<max(0, placeholderCards) {
                forecastStackView.addArrangedSubview(makeShimmerForecastCard())
            }
        }
    }

    private func configureTopSkeletonOverlayIfNeeded() {
        guard !skeletonConfigured else { return }
        guard let parent = cityLabel.superview else { return }

        skeletonConfigured = true

        func attach(_ shimmer: ShimmerView, to view: UIView, cornerRadius: CGFloat) {
            shimmer.translatesAutoresizingMaskIntoConstraints = false
            shimmer.layer.cornerRadius = cornerRadius
            parent.addSubview(shimmer)
            NSLayoutConstraint.activate([
                shimmer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                shimmer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                shimmer.topAnchor.constraint(equalTo: view.topAnchor),
                shimmer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
            shimmer.isHidden = true
        }

        attach(shimmerCity, to: cityLabel, cornerRadius: 10)
        attach(shimmerIcon, to: iconImageView, cornerRadius: 20)
        attach(shimmerTemp, to: tempLabel, cornerRadius: 14)

        shimmerDetailsContainer.translatesAutoresizingMaskIntoConstraints = false
        shimmerDetailsContainer.backgroundColor = .clear
        parent.addSubview(shimmerDetailsContainer)
        NSLayoutConstraint.activate([
            shimmerDetailsContainer.leadingAnchor.constraint(equalTo: detailsLabel.leadingAnchor),
            shimmerDetailsContainer.trailingAnchor.constraint(equalTo: detailsLabel.trailingAnchor),
            shimmerDetailsContainer.topAnchor.constraint(equalTo: detailsLabel.topAnchor),
            shimmerDetailsContainer.bottomAnchor.constraint(equalTo: detailsLabel.bottomAnchor)
        ])

        shimmerDetails1.translatesAutoresizingMaskIntoConstraints = false
        shimmerDetails2.translatesAutoresizingMaskIntoConstraints = false
        shimmerDetails1.layer.cornerRadius = 8
        shimmerDetails2.layer.cornerRadius = 8
        shimmerDetailsContainer.addSubview(shimmerDetails1)
        shimmerDetailsContainer.addSubview(shimmerDetails2)
        NSLayoutConstraint.activate([
            shimmerDetails1.leadingAnchor.constraint(equalTo: shimmerDetailsContainer.leadingAnchor),
            shimmerDetails1.topAnchor.constraint(equalTo: shimmerDetailsContainer.topAnchor),
            shimmerDetails1.heightAnchor.constraint(equalToConstant: 14),
            shimmerDetails1.widthAnchor.constraint(equalTo: shimmerDetailsContainer.widthAnchor, multiplier: 0.75),

            shimmerDetails2.leadingAnchor.constraint(equalTo: shimmerDetailsContainer.leadingAnchor),
            shimmerDetails2.topAnchor.constraint(equalTo: shimmerDetails1.bottomAnchor, constant: 6),
            shimmerDetails2.heightAnchor.constraint(equalToConstant: 14),
            shimmerDetails2.widthAnchor.constraint(equalTo: shimmerDetailsContainer.widthAnchor, multiplier: 0.55),
            shimmerDetails2.bottomAnchor.constraint(lessThanOrEqualTo: shimmerDetailsContainer.bottomAnchor)
        ])
        shimmerDetailsContainer.isHidden = true
    }

    private func setTopSkeleton(_ enabled: Bool) {
        configureTopSkeletonOverlayIfNeeded()

        // Keep layout identical (no jumps): hide via alpha, not isHidden.
        let contentAlpha: CGFloat = enabled ? 0.0 : 1.0
        cityLabel.alpha = contentAlpha
        iconImageView.alpha = contentAlpha
        tempLabel.alpha = contentAlpha
        detailsLabel.alpha = contentAlpha
        activityIndicator.isHidden = true

        shimmerCity.isHidden = !enabled
        shimmerIcon.isHidden = !enabled
        shimmerTemp.isHidden = !enabled
        shimmerDetailsContainer.isHidden = !enabled

        if enabled {
            shimmerCity.startAnimating()
            shimmerIcon.startAnimating()
            shimmerTemp.startAnimating()
            shimmerDetails1.startAnimating()
            shimmerDetails2.startAnimating()
        } else {
            shimmerCity.stopAnimating()
            shimmerIcon.stopAnimating()
            shimmerTemp.stopAnimating()
            shimmerDetails1.stopAnimating()
            shimmerDetails2.stopAnimating()
        }
    }

    private func makeShimmerForecastCard() -> UIView {
        let container = UIView()
        container.backgroundColor = .secondarySystemGroupedBackground
        container.layer.cornerRadius = 12
        container.layer.masksToBounds = true

        let h = UIStackView()
        h.axis = .horizontal
        h.alignment = .center
        h.spacing = 12
        h.translatesAutoresizingMaskIntoConstraints = false

        let icon = ShimmerView()
        icon.layer.cornerRadius = 14
        icon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 28),
            icon.heightAnchor.constraint(equalToConstant: 28)
        ])

        let line1 = ShimmerView()
        line1.layer.cornerRadius = 8
        line1.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            line1.heightAnchor.constraint(equalToConstant: 14),
            line1.widthAnchor.constraint(equalToConstant: 140)
        ])

        let line2 = ShimmerView()
        line2.layer.cornerRadius = 8
        line2.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            line2.heightAnchor.constraint(equalToConstant: 12),
            line2.widthAnchor.constraint(equalToConstant: 110)
        ])

        let v = UIStackView(arrangedSubviews: [line1, line2])
        v.axis = .vertical
        v.spacing = 6
        v.alignment = .leading

        h.addArrangedSubview(icon)
        h.addArrangedSubview(v)

        container.addSubview(h)
        NSLayoutConstraint.activate([
            h.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            h.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            h.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
            h.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -10),
            container.heightAnchor.constraint(greaterThanOrEqualToConstant: 54)
        ])

        icon.startAnimating()
        line1.startAnimating()
        line2.startAnimating()
        return container
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

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
