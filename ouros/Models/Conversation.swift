//
//  Conversation.swift
//  ouros
//
//  Created by Mischa McLaughlin on 16/11/2026.
//

import Foundation

struct Conversation: Identifiable {
	let id = UUID()
	var createdAt: Date = .now
	var updatedAt: Date
	var title: String
	var messages: [Message]
}
