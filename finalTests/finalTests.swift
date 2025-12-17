import XCTest
@testable import final


final class OpenMeteoDecodingTests: XCTestCase {
    func testDecodeGeocodingResponse() throws {
        let json = """
        {
          "results": [
            {
              "id": 123,
              "name": "Almaty",
              "latitude": 43.2567,
              "longitude": 76.9286,
              "country": "Kazakhstan",
              "country_code": "KZ",
              "admin1": "Almaty",
              "timezone": "Asia/Almaty",
              "population": 2000000
            }
          ]
        }
        """
        
        let data = Data(json.utf8)
        let decoded = try JSONDecoder().decode(OpenMeteoGeocodingResponse.self, from: data)
        
        XCTAssertEqual(decoded.results?.count, 1)
        XCTAssertEqual(decoded.results?.first?.name, "Almaty")
        XCTAssertEqual(decoded.results?.first?.countryCode, "KZ")
        XCTAssertEqual(decoded.results?.first?.admin1, "Almaty")
    }
    func testDecodeForecastResponse() throws {
            let json = """
            {
              "latitude": 43.25,
              "longitude": 76.93,
              "timezone": "Asia/Almaty",
              "current": {
                "time": "2025-12-17T10:00",
                "temperature_2m": -2.5,
                "weather_code": 3,
                "wind_speed_10m": 12.0
              },
              "hourly": {
                "time": ["2025-12-17T10:00", "2025-12-17T11:00"],
                "temperature_2m": [-2.5, -2.0],
                "weather_code": [3, 2]
              },
              "daily": {
                "time": ["2025-12-17", "2025-12-18"],
                "temperature_2m_max": [0.0, 1.0],
                "temperature_2m_min": [-5.0, -6.0],
                "weather_code": [3, 1]
              }
            }
            """

            let data = Data(json.utf8)
            let decoded = try JSONDecoder().decode(OpenMeteoForecastResponse.self, from: data)

            XCTAssertEqual(decoded.timezone, "Asia/Almaty")
            XCTAssertEqual(decoded.current?.weatherCode, 3)
            XCTAssertEqual(decoded.hourly?.time.count, 2)
            XCTAssertEqual(decoded.daily?.time.count, 2)
            XCTAssertEqual(decoded.daily?.temperature2mMin?.first, -5.0)
        }
}
