//
//  Conversation.swift
//  ouros
//
//  Created by Mischa McLaughlin on 16/11/2026.
//
import Foundation
import SwiftData

@Model
final class Conversation {
	var id: UUID = UUID()
	var createdAt: Date
	var updatedAt: Date
	var title: String

	@Relationship(deleteRule: .cascade)
	var messages: [Message] = []

	var orderedMessages: [Message] {
		messages.sorted { lhs, rhs in
			if lhs.position == rhs.position {
				return lhs.id.uuidString < rhs.id.uuidString
			}
			return lhs.position < rhs.position
		}
	}

	init(
		createdAt: Date = .now,
		updatedAt: Date,
		title: String,
		messages: [Message]
	) {
		self.createdAt = createdAt
		self.updatedAt = updatedAt
		self.title = title
		for (position, message) in messages.enumerated() {
			message.position = position
		}
		self.messages = messages
	}

	func appendMessage(_ message: Message) {
		message.position = (messages.map(\.position).max() ?? -1) + 1
		messages.append(message)
	}
}
