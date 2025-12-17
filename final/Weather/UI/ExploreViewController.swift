import UIKit

class ExploreViewController: UITableViewController, UISearchResultsUpdating {
    private enum Mode: Int {
        case search = 0
        case favorites = 1
    }

    private let api = WeatherServices.api
    private let storage = WeatherServices.storage

    private var mode: Mode = .search {
        didSet { applyMode() }
    }

    private var favorites: [City] = []
    private var results: [City] = []
    private var currentQuery: String = ""
    private var currentCount: Int = 10
    private var isLoading: Bool = false

    private let searchController = UISearchController(searchResultsController: nil)
    private var searchWorkItem: DispatchWorkItem?
    private var spinner: UIActivityIndicatorView?
    private let modeControl = UISegmentedControl(items: ["Search", "Favorites"])

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Explore"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always

        view.backgroundColor = .systemGroupedBackground
        tableView.backgroundColor = .systemGroupedBackground
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        tableView.separatorStyle = .none

        modeControl.selectedSegmentIndex = Mode.search.rawValue
        modeControl.addTarget(self, action: #selector(modeChanged), for: .valueChanged)
        navigationItem.titleView = modeControl

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
        applyMode()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        favorites = storage.loadFavorites()
        tableView.reloadData()
        updateBackground()
    }

    @objc private func modeChanged() {
        mode = Mode(rawValue: modeControl.selectedSegmentIndex) ?? .search
    }

    private func applyMode() {
        switch mode {
        case .search:
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
        case .favorites:
            searchController.isActive = false
            navigationItem.searchController = nil
            navigationItem.hidesSearchBarWhenScrolling = true
        }
        tableView.reloadData()
        updateBackground()
    }

    @objc private func refreshPulled() {
        if mode == .search, !currentQuery.isEmpty {
            Task { @MainActor in
                await fetchCities(query: currentQuery, count: currentCount, showSpinner: false)
            }
        } else {
            favorites = storage.loadFavorites()
            tableView.reloadData()
            refreshControl?.endRefreshing()
            updateBackground()
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch mode {
        case .search: return results.count
        case .favorites: return favorites.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CityCell", for: indexPath)
        let city = (mode == .search) ? results[indexPath.row] : favorites[indexPath.row]

        let isFav = storage.isFavorite(city)
        if let cityCell = cell as? CityTableViewCell {
            let title = storage.displayTitle(for: city)
            let parts = [city.admin1, city.country].compactMap { $0 }.filter { !$0.isEmpty }
            cityCell.configure(
                title: title,
                subtitle: parts.joined(separator: ", "),
                icon: UIImage(systemName: isFav ? "heart.fill" : "mappin.and.ellipse"),
                iconColor: isFav ? .systemPink : .secondaryLabel
            )
        } else {
            cell.textLabel?.text = storage.displayTitle(for: city)
            cell.imageView?.image = UIImage(systemName: isFav ? "heart.fill" : "mappin.and.ellipse")
            cell.imageView?.tintColor = isFav ? .systemPink : .secondaryLabel
            cell.accessoryType = .disclosureIndicator
        }
        return cell
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "ShowCityDetails" else { return }
        guard let details = segue.destination as? CityDetailsViewController else { return }
        guard let indexPath = tableView.indexPathForSelectedRow else { return }
        let city = (mode == .search) ? results[indexPath.row] : favorites[indexPath.row]
        details.city = city
        storage.saveSelectedCity(city)
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let city = (mode == .search) ? results[indexPath.row] : favorites[indexPath.row]
        let isFav = storage.isFavorite(city)
        let title = isFav ? "Unfavorite" : "Favorite"

        let action = UIContextualAction(style: .normal, title: title) { [weak self] _, _, done in
            guard let self else { done(false); return }
            self.storage.toggleFavorite(city)
            self.favorites = self.storage.loadFavorites()
            self.tableView.reloadData()
            self.updateBackground()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            done(true)
        }
        action.backgroundColor = isFav ? .systemGray : .systemPink
        action.image = UIImage(systemName: isFav ? "heart.slash" : "heart")

        return UISwipeActionsConfiguration(actions: [action])
    }

    func updateSearchResults(for searchController: UISearchController) {
        let text = (searchController.searchBar.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        currentQuery = text
        currentCount = 10

        searchWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                await self.fetchCities(query: text, count: 10, showSpinner: true)
            }
        }
        searchWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: work)
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard mode == .search else { return }
        guard indexPath.row >= results.count - 2 else { return }
        guard !isLoading else { return }
        guard !currentQuery.isEmpty else { return }

        currentCount = min(50, currentCount + 10)
        Task { @MainActor in
            await fetchCities(query: currentQuery, count: currentCount, showSpinner: false)
        }
    }

    @MainActor
    private func fetchCities(query: String, count: Int, showSpinner: Bool) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            results = []
            tableView.reloadData()
            refreshControl?.endRefreshing()
            updateBackground()
            return
        }

        isLoading = true
        if showSpinner { spinner?.startAnimating() }
        do {
            results = try await api.searchCities(query: trimmed, count: count, language: "en")
            tableView.reloadData()
            updateBackground()
        } catch {
            showError(error)
        }
        spinner?.stopAnimating()
        refreshControl?.endRefreshing()
        isLoading = false
    }

    func activateSearch() {
        modeControl.selectedSegmentIndex = Mode.search.rawValue
        mode = .search
        searchController.isActive = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.searchController.searchBar.becomeFirstResponder()
        }
    }

    private func updateBackground() {
        if mode == .search, results.isEmpty, !currentQuery.isEmpty {
            tableView.backgroundView = makeEmptyLabel("No results.\nTry another query.")
        } else if mode == .favorites, favorites.isEmpty {
            tableView.backgroundView = makeEmptyLabel("No favorites yet.\nAdd a city from Search.")
        } else if mode == .search, results.isEmpty {
            tableView.backgroundView = makeEmptyLabel("Search for a city to add it.")
        } else {
            tableView.backgroundView = nil
        }
    }

    private func makeEmptyLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        label.text = text
        return label
    }

    @MainActor
    private func showError(_ error: Error) {
        let alert = UIAlertController(title: "Network error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
