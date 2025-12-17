import UIKit

final class ForecastViewController: UITableViewController, UISearchResultsUpdating {
    private let api = WeatherServices.api
    private let storage = WeatherServices.storage

    private var favorites: [City] = []
    private var results: [City] = []
    private var currentQuery: String = ""
    private var currentCount: Int = 10
    private var isLoading: Bool = false

    private let searchController = UISearchController(searchResultsController: nil)
    private var searchWorkItem: DispatchWorkItem?
    private var spinner: UIActivityIndicatorView?

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

        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.hidesWhenStopped = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: spinner)
        self.spinner = spinner

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refreshPulled), for: .valueChanged)

        favorites = storage.loadFavorites()
        updateBackground()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        favorites = storage.loadFavorites()
        tableView.reloadData()
        updateBackground()
    }

    @objc private func refreshPulled() {
        if isSearching {
            Task { @MainActor in
                await fetchCities(query: currentQuery, count: currentCount, showRefresh: false)
            }
        } else {
            favorites = storage.loadFavorites()
            tableView.reloadData()
            refreshControl?.endRefreshing()
            updateBackground()
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        isSearching ? results.count : favorites.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CityCell", for: indexPath)
        let city = isSearching ? results[indexPath.row] : favorites[indexPath.row]

        if let cityCell = cell as? CityTableViewCell {
            let title = storage.displayTitle(for: city)
            let parts = [city.admin1, city.country].compactMap { $0 }.filter { !$0.isEmpty }
            cityCell.configure(title: title, subtitle: parts.joined(separator: ", "))
        } else {
            cell.textLabel?.text = storage.displayTitle(for: city)
        }
        
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func updateSearchResults(for searchController: UISearchController) {
        let text = (searchController.searchBar.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        currentQuery = text
        currentCount = 10

        searchWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                await self.fetchCities(query: text, count: 10, showRefresh: true)
            }
        }
        searchWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: work)
    }

    private var isSearching: Bool {
        searchController.isActive && !((searchController.searchBar.text ?? "").isEmpty)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "ShowCityDetails" else { return }
        guard let details = segue.destination as? CityDetailsViewController else { return }
        guard let indexPath = tableView.indexPathForSelectedRow else { return }
        let city = isSearching ? results[indexPath.row] : favorites[indexPath.row]
        details.city = city
        storage.saveSelectedCity(city)
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard isSearching else { return }
        guard indexPath.row >= results.count - 2 else { return }
        guard !isLoading else { return }
        guard !currentQuery.isEmpty else { return }

        currentCount = min(50, currentCount + 10)
        Task { @MainActor in
            await fetchCities(query: currentQuery, count: currentCount, showRefresh: false)
        }
    }

    @MainActor
    private func fetchCities(query: String, count: Int, showRefresh: Bool) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            results = []
            tableView.reloadData()
            refreshControl?.endRefreshing()
            updateBackground()
            return
        }

        isLoading = true
        if showRefresh { spinner?.startAnimating() }
        do {
            let cities = try await api.searchCities(query: trimmed, count: count, language: "en")
            results = cities
            tableView.reloadData()
            updateBackground()
        } catch {
            showError(error)
        }
        spinner?.stopAnimating()
        refreshControl?.endRefreshing()
        isLoading = false
    }

    private func updateBackground() {
        if isSearching, results.isEmpty, !currentQuery.isEmpty {
            let label = UILabel()
            label.textAlignment = .center
            label.numberOfLines = 0
            label.textColor = .secondaryLabel
            label.text = "No results.\nTry another query."
            tableView.backgroundView = label
        } else if !isSearching, favorites.isEmpty {
            let label = UILabel()
            label.textAlignment = .center
            label.numberOfLines = 0
            label.textColor = .secondaryLabel
            label.text = "Search a city above.\nAdd it to Favorites from Details."
            tableView.backgroundView = label
        } else {
            tableView.backgroundView = nil
        }
    }

    @MainActor
    private func showError(_ error: Error) {
        let alert = UIAlertController(title: "Network error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}


