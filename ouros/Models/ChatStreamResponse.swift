//
//  ChatStreamResponse.swift
//  ouros
//
//  Created by Mischa McLaughlin on 17/11/2026.
//

struct ChatStreamResponse: Decodable {
	let choices: [Choice]

	struct Choice: Decodable {
		let delta: Delta
	}

	struct Delta: Decodable {
		let reasoning: String?
		let content: String?
	}
}
