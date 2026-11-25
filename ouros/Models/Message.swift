//
//  Messages.swift
//  ouros
//
//  Created by Mischa McLaughlin on 15/11/2026.
//
import Foundation
import SwiftData

@Model
final class Message {
	var id = UUID()
	var position = 0
	var role: Role
	var reasoning: String
	var content: String
	private(set) var isExpanded: Bool?

	var modelID: String
	var modelAlias: String

	var model: LocalModel {
		LocalModel(id: modelID, alias: modelAlias)
	}

	init(
		role: Role,
		model: LocalModel,
		reasoning: String = "",
		content: String
	) {
		self.role = role
		self.modelID = model.id
		self.modelAlias = model.alias
		self.reasoning = reasoning
		self.content = content
		self.isExpanded = role == .assistant ? false : nil
	}

	func setIsExpanded(_ isExpanded: Bool?) {
		guard role == .assistant else { return }
		self.isExpanded = isExpanded
	}

	enum Role: String, Codable {
		case user
		case assistant
	}
}
