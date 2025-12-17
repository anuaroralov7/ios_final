import UIKit

final class CityDetailsViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var titleTextField: UITextField!
    @IBOutlet private weak var noteTextView: UITextView!
    @IBOutlet private weak var forecastStackView: UIStackView!
    private var spinner: UIActivityIndicatorView?
    private var favoriteBarButton: UIBarButtonItem?

    var city: City?

    private let api = WeatherServices.api
    private let storage = WeatherServices.storage
    
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
        view.backgroundColor = .systemGroupedBackground

        titleTextField.delegate = self
        noteTextView.delegate = self

        noteTextView.layer.borderWidth = 1
        noteTextView.layer.borderColor = UIColor.separator.cgColor
        noteTextView.layer.cornerRadius = 10
        noteTextView.backgroundColor = .secondarySystemBackground

        iconImageView.tintColor = .systemBlue
        iconImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 44, weight: .semibold)
        
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.hidesWhenStopped = true
        self.spinner = spinner
        let spinnerItem = UIBarButtonItem(customView: spinner)
        
        let favoriteButton = UIButton(type: .system)
        favoriteButton.addTarget(self, action: #selector(favoriteBarTapped), for: .touchUpInside)
        let favoriteItem = UIBarButtonItem(customView: favoriteButton)
        self.favoriteBarButton = favoriteItem
        
        navigationItem.rightBarButtonItems = [favoriteItem, spinnerItem]

        applyCityStatic()
        loadUserData()
        refreshForecast()
    }

    private func applyCityStatic() {
        guard let city else {
            title = "City"
            subtitleLabel.text = ""
            subtitleLabel.isHidden = true
            iconImageView.image = UIImage(systemName: "cloud")
            updateFavoriteBarButton(isFavorite: false)
            return
        }

        let name = storage.displayTitle(for: city)
        title = name

        let parts = [city.admin1, city.country].compactMap { $0 }.filter { !$0.isEmpty }
        subtitleLabel.text = parts.joined(separator: ", ")
        subtitleLabel.isHidden = parts.isEmpty
        iconImageView.image = UIImage(systemName: "cloud")
    }

    private func loadUserData() {
        guard let city else { return }
        titleTextField.text = storage.loadCustomTitle(for: city.id)
        noteTextView.text = storage.loadNote(for: city.id)
        updateFavoriteBarButton(isFavorite: storage.isFavorite(city))
    }

    private func updateFavoriteBarButton(isFavorite: Bool) {
        guard let favoriteItem = favoriteBarButton,
              let button = favoriteItem.customView as? UIButton else { return }
        let image = UIImage(systemName: isFavorite ? "heart.fill" : "heart")
        button.setImage(image, for: .normal)
        button.tintColor = isFavorite ? .systemPink : .label
    }

    private func refreshForecast() {
        guard let city else { return }
        spinner?.startAnimating()
        Task { @MainActor in
            defer { spinner?.stopAnimating() }
            do {
                let settings = storage.loadSettings()
                let forecast = try await api.fetchForecast(
                    latitude: city.latitude,
                    longitude: city.longitude,
                    temperatureUnit: settings.apiTemperatureUnit,
                    windSpeedUnit: settings.apiWindSpeedUnit,
                    forecastDays: settings.apiForecastDays
                )
                applyForecast(forecast, settings: settings)
            } catch {
                showError(error)
            }
        }
    }

    @MainActor
    private func applyForecast(_ forecast: OpenMeteoForecastResponse, settings: WeatherSettings) {
        if let code = forecast.current?.weatherCode {
            let mapped = WeatherCode.iconAndText(for: code)
            iconImageView.image = UIImage(systemName: mapped.symbol)
        }

        guard let city else { return }
        let base = [city.admin1, city.country].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")

        if let temp = forecast.current?.temperature2m {
            let rounded = Int(temp.rounded())
            let unit = settings.temperatureUnit == .celsius ? "°C" : "°F"
            subtitleLabel.text = base.isEmpty ? "\(rounded)\(unit)" : "\(base) • \(rounded)\(unit)"
            subtitleLabel.isHidden = false
        } else {
            subtitleLabel.text = base
            subtitleLabel.isHidden = base.isEmpty
        }
        
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
    
    private func formatTemp(_ value: Double?, unit: TemperatureUnit) -> String {
        guard let value else { return "—" }
        let rounded = Int(value.rounded())
        return unit == .celsius ? "\(rounded)°C" : "\(rounded)°F"
    }

    @objc private func favoriteBarTapped() {
        guard let city else { return }
        guard let favoriteItem = favoriteBarButton,
              let button = favoriteItem.customView as? UIButton else { return }
        
        storage.toggleFavorite(city)
        let isFav = storage.isFavorite(city)
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        UIView.transition(with: button, duration: 0.2, options: .transitionCrossDissolve, animations: {
            self.updateFavoriteBarButton(isFavorite: isFav)
        }, completion: nil)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let city else { return }
        storage.saveCustomTitle(textField.text ?? "", for: city.id)
        applyCityStatic()
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        guard let city else { return }
        storage.saveNote(textView.text ?? "", for: city.id)
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
