import UIKit

final class SettingsViewController: UIViewController {
    @IBOutlet private weak var temperatureSegmented: UISegmentedControl!
    @IBOutlet private weak var windSegmented: UISegmentedControl!
    @IBOutlet private weak var showWindSwitch: UISwitch!
    @IBOutlet private weak var daysSlider: UISlider!
    @IBOutlet private weak var daysLabel: UILabel!

    private let storage = WeatherServices.storage

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        loadFromStorage()
    }

    private func loadFromStorage() {
        let settings = storage.loadSettings()
        temperatureSegmented.selectedSegmentIndex = settings.temperatureUnit == .celsius ? 0 : 1

        let windUnits: [WindSpeedUnit] = [.kmh, .ms, .mph, .kn]
        windSegmented.selectedSegmentIndex = windUnits.firstIndex(of: settings.windSpeedUnit) ?? 0

        showWindSwitch.isOn = settings.showWind
        daysSlider.minimumValue = 1
        daysSlider.maximumValue = 16
        daysSlider.value = Float(settings.forecastDays)
        updateDaysLabel(Int(settings.forecastDays))
    }

    private func save() {
        let tempUnit: TemperatureUnit = temperatureSegmented.selectedSegmentIndex == 0 ? .celsius : .fahrenheit
        let windUnits: [WindSpeedUnit] = [.kmh, .ms, .mph, .kn]
        let windUnit = windUnits[min(max(0, windSegmented.selectedSegmentIndex), windUnits.count - 1)]
        let days = Int(daysSlider.value.rounded())

        let settings = WeatherSettings(
            temperatureUnit: tempUnit,
            windSpeedUnit: windUnit,
            showWind: showWindSwitch.isOn,
            forecastDays: days
        )
        storage.saveSettings(settings)
        updateDaysLabel(days)
    }

    private func updateDaysLabel(_ days: Int) {
        daysLabel.text = "Forecast days: \(days)"
    }

    @IBAction private func temperatureChanged(_ sender: UISegmentedControl) {
        save()
    }

    @IBAction private func windChanged(_ sender: UISegmentedControl) {
        save()
    }

    @IBAction private func showWindChanged(_ sender: UISwitch) {
        save()
    }

    @IBAction private func daysChanged(_ sender: UISlider) {
        save()
    }
}
