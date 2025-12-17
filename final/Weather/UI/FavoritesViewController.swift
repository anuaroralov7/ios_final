import UIKit

final class FavoritesViewController: UITableViewController {
    private let storage = WeatherServices.storage
    private var favorites: [City] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Favorites"
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refreshFavorites), for: .valueChanged)
        refreshFavorites()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshFavorites()
    }

    @objc private func refreshFavorites() {
        favorites = storage.loadFavorites()
        tableView.reloadData()
        refreshControl?.endRefreshing()
        updateEmptyState()
    }

    private func updateEmptyState() {
        if favorites.isEmpty {
            let label = UILabel()
            label.textAlignment = .center
            label.numberOfLines = 0
            label.textColor = .secondaryLabel
            label.text = "No favorites yet.\nOpen Forecast and add a city."
            tableView.backgroundView = label
        } else {
            tableView.backgroundView = nil
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        favorites.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CityCell", for: indexPath)
        let city = favorites[indexPath.row]

        if let cityCell = cell as? CityTableViewCell {
            let subtitle = [city.admin1, city.country].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")
            cityCell.configure(title: storage.displayTitle(for: city), subtitle: subtitle)
        } else {
            cell.textLabel?.text = storage.displayTitle(for: city)
        }
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "ShowCityDetails" else { return }
        guard let details = segue.destination as? CityDetailsViewController else { return }
        let city: City?
        if let passed = sender as? City {
            city = passed
        } else if let indexPath = tableView.indexPathForSelectedRow {
            city = favorites[indexPath.row]
        } else {
            city = nil
        }
        if let city {
            details.city = city
            storage.saveSelectedCity(city)
        }
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let city = favorites[indexPath.row]
            storage.toggleFavorite(city)
            favorites.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            updateEmptyState()
        }
    }
}
