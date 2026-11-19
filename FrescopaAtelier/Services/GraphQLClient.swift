import Foundation

/// Minimal, typed GraphQL-over-HTTP client.
struct GraphQLClient: Sendable {
    struct Configuration: Sendable {
        var endpoint: URL
        var headers: [String: String]
        var timeout: TimeInterval = 15
    }

    enum ClientError: LocalizedError, Equatable {
        case http(Int)
        case graphQL([String])
        case emptyResponse

        var errorDescription: String? {
            switch self {
            case .http(let code): "The shop is unavailable right now (\(code))."
            case .graphQL(let messages): messages.first ?? "The shop returned an error."
            case .emptyResponse: "The shop returned no data."
            }
        }
    }

    let configuration: Configuration
    var session: URLSession = .shared

    /// Executes `query` with `variables` and decodes the `data` payload as `Response`.
    func execute<Response: Decodable & Sendable, Variables: Encodable & Sendable>(
        _ query: String,
        variables: Variables,
        as: Response.Type = Response.self
    ) async throws -> Response {
        var request = URLRequest(url: configuration.endpoint, timeoutInterval: configuration.timeout)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        for (name, value) in configuration.headers { request.setValue(value, forHTTPHeaderField: name) }
        request.httpBody = try JSONEncoder().encode(Body(query: query, variables: variables))

        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw ClientError.http(http.statusCode)
        }
        let envelope = try JSONDecoder().decode(Envelope<Response>.self, from: data)
        if let errors = envelope.errors, !errors.isEmpty, envelope.data == nil {
            throw ClientError.graphQL(errors.map(\.message))
        }
        guard let payload = envelope.data else { throw ClientError.emptyResponse }
        return payload
    }

    private struct Body<Variables: Encodable>: Encodable {
        let query: String
        let variables: Variables
    }

    private struct Envelope<Payload: Decodable>: Decodable {
        let data: Payload?
        let errors: [Message]?
        struct Message: Decodable { let message: String }
    }
}

/// Use when a query takes no variables.
struct NoVariables: Encodable, Sendable {}
