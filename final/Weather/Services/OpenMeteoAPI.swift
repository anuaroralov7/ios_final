import Foundation

final class OpenMeteoAPI {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    enum APIError: Error, LocalizedError {
        case invalidURL
        case invalidResponse
        case httpStatus(Int)
        case decoding(Error)
        case transport(Error)

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid request URL."
            case .invalidResponse:
                return "Invalid server response."
            case .httpStatus(let code):
                return "Server returned status code \(code)."
            case .decoding:
                return "Failed to parse server response."
            case .transport(let error):
                return error.localizedDescription
            }
        }
    }

    func searchCities(query: String, count: Int = 10, language: String = "en") async throws -> [City] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        var components = URLComponents()
        components.scheme = WeatherAppConfig.geocodingBaseURL.scheme
        components.host = WeatherAppConfig.geocodingBaseURL.host
        components.path = "/v1/search"
        components.queryItems = [
            URLQueryItem(name: "name", value: trimmed),
            URLQueryItem(name: "count", value: String(max(1, min(50, count)))),
            URLQueryItem(name: "language", value: language),
            URLQueryItem(name: "format", value: "json")
        ]

        guard let url = components.url else { throw APIError.invalidURL }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw APIError.transport(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw APIError.httpStatus(http.statusCode)
        }

        let decoded: OpenMeteoGeocodingResponse
        do {
            decoded = try JSONDecoder().decode(OpenMeteoGeocodingResponse.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }

        return (decoded.results ?? []).map { r in
            City(
                name: r.name,
                country: r.country ?? "",
                admin1: r.admin1,
                latitude: r.latitude,
                longitude: r.longitude
            )
        }
    }

    func fetchForecast(
        latitude: Double,
        longitude: Double,
        temperatureUnit: String = "celsius",
        windSpeedUnit: String = "kmh",
        forecastDays: Int = 7
    ) async throws -> OpenMeteoForecastResponse {
        var components = URLComponents()
        components.scheme = WeatherAppConfig.forecastBaseURL.scheme
        components.host = WeatherAppConfig.forecastBaseURL.host
        components.path = "/v1/forecast"
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "forecast_days", value: String(max(1, min(16, forecastDays)))),
            URLQueryItem(name: "temperature_unit", value: temperatureUnit),
            URLQueryItem(name: "wind_speed_unit", value: windSpeedUnit),
            URLQueryItem(name: "current", value: "temperature_2m,weather_code,wind_speed_10m"),
            URLQueryItem(name: "hourly", value: "temperature_2m,weather_code"),
            URLQueryItem(name: "daily", value: "temperature_2m_max,temperature_2m_min,weather_code")
        ]

        guard let url = components.url else { throw APIError.invalidURL }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw APIError.transport(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw APIError.httpStatus(http.statusCode)
        }

        do {
            return try JSONDecoder().decode(OpenMeteoForecastResponse.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }
}



