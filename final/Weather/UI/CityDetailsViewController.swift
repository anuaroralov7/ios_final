import UIKit

final class CityDetailsViewController: UIViewController, UITextViewDelegate, UITextFieldDelegate {
    @IBOutlet private weak var cityTitleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var titleTextField: UITextField!
    @IBOutlet private weak var noteTextView: UITextView!
    @IBOutlet private weak var favoriteButton: UIButton!
    private var spinner: UIActivityIndicatorView?

    var city: City?

    private let api = WeatherServices.api
    private let storage = WeatherServices.storage

    override func viewDidLoad() {
        super.viewDidLoad()
        titleTextField.delegate = self
        noteTextView.delegate = self

        iconImageView.tintColor = .systemBlue
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.hidesWhenStopped = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: spinner)
        self.spinner = spinner

        noteTextView.layer.borderWidth = 1
        noteTextView.layer.borderColor = UIColor.separator.cgColor
        noteTextView.layer.cornerRadius = 10

        applyCityStatic()
        loadUserData()
        refreshForecast()
    }

    private func applyCityStatic() {
        guard let city else {
            cityTitleLabel.text = "City"
            title = "City"
            subtitleLabel.text = ""
            subtitleLabel.isHidden = true
            iconImageView.image = UIImage(systemName: "cloud")
            return
        }

        let name = storage.displayTitle(for: city)
        cityTitleLabel.text = name
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
        updateFavoriteUI(isFavorite: storage.isFavorite(city))
    }

    private func updateFavoriteUI(isFavorite: Bool) {
        favoriteButton.setTitle(isFavorite ? "Remove from Favorites" : "Add to Favorites", for: .normal)
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
    }

    @IBAction private func favoriteTapped(_ sender: UIButton) {
        guard let city else { return }
        storage.toggleFavorite(city)
        let isFav = storage.isFavorite(city)
        updateFavoriteUI(isFavorite: isFav)

        UIView.animate(withDuration: 0.15, animations: {
            sender.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        }, completion: { _ in
            UIView.animate(withDuration: 0.15) { sender.transform = .identity }
        })
    }

    @IBAction private func saveTapped(_ sender: UIButton) {
        guard let city else { return }
        view.endEditing(true)
        storage.saveNote(noteTextView.text ?? "", for: city.id)
        storage.saveCustomTitle(titleTextField.text ?? "", for: city.id)
        storage.saveSelectedCity(city)

        UIView.animate(withDuration: 0.2, animations: {
            sender.alpha = 0.6
        }, completion: { _ in
            UIView.animate(withDuration: 0.2) { sender.alpha = 1 }
        })
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
