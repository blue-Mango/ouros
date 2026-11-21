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

private struct ChatTemplateOptions: Encodable {
	let enableThinking: Bool
	let reasoningEffort: String?

	enum CodingKeys: String, CodingKey {
		case enableThinking = "enable_thinking"
		case reasoningEffort = "reasoning_effort"
	}
}

private struct ChatRequest: Encodable {
	let model: String
	let messages: [ChatMessage]
	let stream = true
	let maxTokens = 4096
	let chatTemplateKwargs: ChatTemplateOptions?
	enum CodingKeys: String, CodingKey {
		case model, messages, stream
		case maxTokens = "max_tokens"
		case chatTemplateKwargs = "chat_template_kwargs"
	}
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

	func chat(
		model: String,
		messages: [Message],
		reasoningEffort: String? = nil,
		enableThinking: Bool? = nil,
		onReasoning: @escaping @MainActor (String) -> Void,
		onChunk: @escaping @MainActor (String) -> Void,
	) async throws -> String {
		let url = URL(string: "http://127.0.0.1:8080/v1/chat/completions")!
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")

		let systemPrompt = """
			You are the assistant in Ouros, a macOS chat app configured to run language
			models through a local MLX server on the user's Mac.

			Answer the user's actual question first. Keep simple answers short and give
			complex tasks the detail they need. Use British English by default and follow
			the user's requested tone and format.

			Keep deliberation proportionate to the task. Once you have a workable answer,
			deliver it. For demonstrations, show the requested examples and explain them
			with brief captions in the final answer.

			State uncertainty plainly. Only claim access to files, tools, the internet,
			or the user's machine when that access has been provided. If a detail is
			missing, make a reasonable assumption when you can. Ask a focused question
			when the missing detail would materially change the answer.

			Use Markdown where it improves readability. End when the request is satisfied.
			"""

		let chatMessages =
			[
				ChatMessage(role: "system", content: systemPrompt)
			]
			+ messages.map {
				ChatMessage(
					role: $0.role == .user ? "user" : "assistant",
					content: $0.content
				)
			}

		request.httpBody = try JSONEncoder().encode(
			ChatRequest(
				model: model,
				messages: chatMessages,
				chatTemplateKwargs: enableThinking.map { enabled in
					ChatTemplateOptions(
						enableThinking: enabled,
						reasoningEffort: enabled ? reasoningEffort : nil
					)
				}
			)
		)

		let (bytes, response) = try await URLSession.shared.bytes(for: request)
		guard let response = response as? HTTPURLResponse,
			response.statusCode == 200
		else {
			throw URLError(.badServerResponse)
		}

		var reply = ""

		for try await line in bytes.lines {
			guard line.hasPrefix("data:") else { continue }

			let payload = String(line.dropFirst(5))
				.trimmingCharacters(in: .whitespaces)

			if payload == "[DONE]" { break }

			let event = try JSONDecoder().decode(
				ChatStreamResponse.self,
				from: Data(payload.utf8)
			)

			if let delta = event.choices.first?.delta {
				if let reasoning = delta.reasoning, !reasoning.isEmpty {
					onReasoning(reasoning)
				}
				if let content = delta.content, !content.isEmpty {
					reply += content
					onChunk(content)
				}
			}
		}

		return reply
	}
}
