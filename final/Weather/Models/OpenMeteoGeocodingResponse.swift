import Foundation

struct OpenMeteoGeocodingResponse: Codable, Sendable {
    let results: [Result]?

    struct Result: Codable, Sendable {
        let id: Int?
        let name: String
        let latitude: Double
        let longitude: Double
        let country: String?
        let countryCode: String?
        let admin1: String?
        let timezone: String?
        let population: Int?

        enum CodingKeys: String, CodingKey {
            case id
            case name
            case latitude
            case longitude
            case country
            case countryCode = "country_code"
            case admin1
            case timezone
            case population
        }
    }
}


