import UIKit

final class ForecastViewController: UITableViewController, UISearchResultsUpdating {
    private var allCities: [City] = [
        City(name: "Almaty", country: "KZ", admin1: "Almaty", latitude: 43.2567, longitude: 76.9286),
        City(name: "Astana", country: "KZ", admin1: nil, latitude: 51.1694, longitude: 71.4491),
        City(name: "Shymkent", country: "KZ", admin1: nil, latitude: 42.3155, longitude: 69.5869),
        City(name: "New York", country: "US", admin1: "New York", latitude: 40.7128, longitude: -74.0060),
        City(name: "London", country: "GB", admin1: "England", latitude: 51.5072, longitude: -0.1276)
    ]
    private var filteredCities: [City] = []
    private let searchController = UISearchController(searchResultsController: nil)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Forecast"
        tableView.keyboardDismissMode = .onDrag
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60

        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
        searchController.searchBar.placeholder = "Search city"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        isSearching ? filteredCities.count : allCities.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CityCell", for: indexPath)
        let city = isSearching ? filteredCities[indexPath.row] : allCities[indexPath.row]

        if let cityCell = cell as? CityTableViewCell {
            let title = city.name
            let parts = [city.admin1, city.country].compactMap { $0 }.filter { !$0.isEmpty }
            cityCell.configure(title: title, subtitle: parts.joined(separator: ", "))
        } else {
            cell.textLabel?.text = city.name
        }

        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func updateSearchResults(for searchController: UISearchController) {
        let text = (searchController.searchBar.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty {
            filteredCities = []
        } else {
            filteredCities = allCities.filter { $0.name.localizedCaseInsensitiveContains(text) }
        }
        tableView.reloadData()
    }

    private var isSearching: Bool {
        searchController.isActive && !((searchController.searchBar.text ?? "").isEmpty)
    }
}


