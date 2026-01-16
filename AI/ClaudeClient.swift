import Foundation

class ClaudeClient {
    static let shared = ClaudeClient()

    private let baseURL = "https://api.anthropic.com/v1/messages"
    private let apiVersion = "2023-06-01"
    private let model = "claude-sonnet-4-20250514"

    private init() {}

    var apiKey: String? {
        KeychainHelper.getAPIKey()
    }

    var isConfigured: Bool {
        apiKey != nil && !(apiKey?.isEmpty ?? true)
    }

    func sendMessage(systemPrompt: String, userMessage: String, maxTokens: Int = 1500) async throws -> String {
        guard let apiKey = apiKey else {
            throw ClaudeAPIError.apiKeyNotConfigured
        }

        guard let url = URL(string: baseURL) else {
            throw ClaudeAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(apiVersion, forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": userMessage]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClaudeAPIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(ClaudeErrorResponse.self, from: data) {
                throw ClaudeAPIError.apiError(errorResponse.error.message)
            }
            throw ClaudeAPIError.httpError(httpResponse.statusCode)
        }

        let apiResponse = try JSONDecoder().decode(ClaudeAPIResponse.self, from: data)

        guard let textContent = apiResponse.content.first(where: { $0.type == "text" }) else {
            throw ClaudeAPIError.noTextContent
        }

        return textContent.text
    }
}

// MARK: - API Response Models

struct ClaudeAPIResponse: Codable {
    let id: String
    let type: String
    let role: String
    let content: [ContentBlock]
    let model: String
    let stopReason: String?
    let stopSequence: String?
    let usage: Usage

    enum CodingKeys: String, CodingKey {
        case id, type, role, content, model
        case stopReason = "stop_reason"
        case stopSequence = "stop_sequence"
        case usage
    }
}

struct ContentBlock: Codable {
    let type: String
    let text: String
}

struct Usage: Codable {
    let inputTokens: Int
    let outputTokens: Int

    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
    }
}

struct ClaudeErrorResponse: Codable {
    let type: String
    let error: ClaudeError
}

struct ClaudeError: Codable {
    let type: String
    let message: String
}

// MARK: - Errors

enum ClaudeAPIError: Error, LocalizedError {
    case apiKeyNotConfigured
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case apiError(String)
    case noTextContent
    case encodingError

    var errorDescription: String? {
        switch self {
        case .apiKeyNotConfigured:
            return "Claude API key is not configured. Please add your API key in Settings."
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from API"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .apiError(let message):
            return "API error: \(message)"
        case .noTextContent:
            return "No text content in response"
        case .encodingError:
            return "Failed to encode request"
        }
    }
}
