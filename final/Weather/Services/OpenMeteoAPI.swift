import Foundation

final class OpenMeteoAPI {
    enum APIError: Error {
        case invalidURL
        case invalidResponse
        case httpStatus(Int)
        case decoding(Error)
        case transport(Error)
    }
}


