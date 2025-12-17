import Foundation

struct City: Codable, Hashable, Identifiable {
    var id: String { "\(name)|\(country)|\(latitude),\(longitude)" }

    let name: String
    let country: String
    let admin1: String?
    let latitude: Double
    let longitude: Double
}
