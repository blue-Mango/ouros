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
	var model: LocalModel
	var reasoning = ""
	var content: String
	private(set) var isExpanded: Bool?

	init(role: Role, model: LocalModel, reasoning: String = "", content: String) {
		self.role = role
		self.model = model
		self.reasoning = reasoning
		self.content = content
		self.isExpanded = role == .assistant ? false : nil
	}

	mutating func setIsExpanded(_ isExpanded: Bool?) {
		guard role == .assistant else { return }
		self.isExpanded = isExpanded
	}

	enum Role {
		case user
		case assistant
	}
}
