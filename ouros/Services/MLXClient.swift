//
//  Ollama.swift
//  ouros
//
//  Created by Mischa McLaughlin on 15/11/2026.
//

import Foundation

private struct ModelsResponse: Decodable {
	let data: [LocalModel]
}

private struct ChatRequest: Encodable {
	let model: String
	let messages: [ChatMessage]
	let stream = false
}

private struct ChatMessage: Encodable {
	let role: String
	let content: String
}

private struct ChatResponse: Decodable {
	let choices: [Choice]

	struct Choice: Decodable {
		let message: Reply
	}

	struct Reply: Decodable {
		let content: String
	}
}

struct MLXClient {
	func fetchModels() async throws -> [LocalModel] {
		let url = URL(string: "http://127.0.0.1:8080/v1/models")!
		let (data, response) = try await URLSession.shared.data(from: url)

		guard let response = response as? HTTPURLResponse,
			response.statusCode == 200
		else {
			throw URLError(.badServerResponse)
		}

		return try JSONDecoder()
			.decode(ModelsResponse.self, from: data)
			.data
	}

	func chat(model: String, messages: [Message]) async throws -> String {
		let url = URL(string: "http://127.0.0.1:8080/v1/chat/completions")!
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")

		let chatMessages = messages.map {
			ChatMessage(
				role: $0.role == .user ? "user" : "assistant",
				content: $0.content
			)
		}
		request.httpBody = try JSONEncoder().encode(
			ChatRequest(model: model, messages: chatMessages)
		)

		let (data, response) = try await URLSession.shared.data(for: request)
		guard let response = response as? HTTPURLResponse,
			response.statusCode == 200
		else {
			throw URLError(.badServerResponse)
		}

		let result = try JSONDecoder().decode(ChatResponse.self, from: data)
		guard let reply = result.choices.first?.message.content else {
			throw URLError(.cannotParseResponse)
		}

		return reply.trimmingCharacters(in: .whitespacesAndNewlines)
	}
}
