//
//  Messages.swift
//  ouros
//
//  Created by Mischa McLaughlin on 15/11/2026.
//

import Foundation

struct Message: Identifiable {
	let id = UUID()
	let role: Role
	var reasoning = ""
	var content: String
	private(set) var isExpanded: Bool?

	init(role: Role, reasoning: String = "", content: String) {
		self.role = role
		self.reasoning = reasoning
		self.content = content
		self.isExpanded = role == .assistant ? false : nil
	}

	mutating func setIsExpanded(_ isExpanded: Bool) {
		guard role == .assistant else { return }
		self.isExpanded = isExpanded
	}

	enum Role {
		case user
		case assistant
	}
}
