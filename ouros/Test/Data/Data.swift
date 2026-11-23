//
//  Data.swift
//  ouros
//
//  Created by Mischa McLaughlin on 22/11/2026.
//

import SwiftUI

let fakeConversations: [Conversation] = [
	Conversation(
		createdAt: Calendar.current.date(
			from: DateComponents(
				year: 2026,
				month: 11,
				day: 17,
				hour: 21,
				minute: 0
			)
		)!,
		updatedAt: Calendar.current.date(
			from: DateComponents(
				year: 2026,
				month: 11,
				day: 17,
				hour: 21,
				minute: 0
			)
		)!,
		title: "New convo",
		messages: [
			Message(role: .user, model: fakeModels[0], content: "Hello"),
			Message(role: .assistant, model: fakeModels[0], content: "Hi there!"),
			Message(role: .user, model: fakeModels[0], content: "How you doing?!"),
			Message(role: .assistant, model: fakeModels[0], content: "Convo1!"),
		],
	),
	Conversation(
		createdAt: .now,
		updatedAt: .now,
		title: "Another new convo",
		messages: [
			Message(role: .user, model: fakeModels[1], content: "Convo2"),
			Message(role: .assistant, model: fakeModels[1], content: "Hi there!"),
			Message(role: .user, model: fakeModels[1], content: "How you doing?!"),
			Message(role: .assistant, model: fakeModels[1], content: "Chillllaxing!"),
		]
	),
	Conversation(
		createdAt: Calendar.current.date(
			from: DateComponents(
				year: 2026,
				month: 11,
				day: 17,
				hour: 21,
				minute: 0
			)
		)!,
		updatedAt: Calendar.current.date(
			from: DateComponents(
				year: 2026,
				month: 11,
				day: 17,
				hour: 21,
				minute: 0
			)
		)!,
		title: "Annnnd another",
		messages: [
			Message(role: .user, model: fakeModels[2], content: "Hello"),
			Message(role: .assistant, model: fakeModels[2], content: "Convo3"),
			Message(role: .user, model: fakeModels[2], content: "How you doing?!"),
			Message(role: .assistant, model: fakeModels[2], content: "noice"),
		]
	),
	Conversation(
		createdAt: Calendar.current.date(
			from: DateComponents(
				year: 2026,
				month: 11,
				day: 17,
				hour: 21,
				minute: 0
			)
		)!,
		updatedAt: Calendar.current.date(
			from: DateComponents(
				year: 2026,
				month: 11,
				day: 17,
				hour: 21,
				minute: 0
			)
		)!,
		title: "again - new convo",
		messages: [
			Message(role: .user, model: fakeModels[3], content: "Convo4"),
			Message(role: .assistant, model: fakeModels[3], content: "Hi there!"),
		]
	),
	Conversation(
		createdAt: Calendar.current.date(
			from: DateComponents(
				year: 2026,
				month: 11,
				day: 17,
				hour: 21,
				minute: 0
			)
		)!,
		updatedAt: Calendar.current.date(
			from: DateComponents(
				year: 2026,
				month: 11,
				day: 17,
				hour: 21,
				minute: 0
			)
		)!,
		title: "last convo added manually",
		messages: [
			Message(role: .user, model: fakeModels[4], content: "Convo 5"),
			Message(role: .assistant, model: fakeModels[4], content: "Hi again!"),
		]
	),
	Conversation(
		createdAt: Calendar.current.date(
			from: DateComponents(
				year: 2026,
				month: 11,
				day: 17,
				hour: 21,
				minute: 0
			)
		)!,
		updatedAt: Calendar.current.date(
			from: DateComponents(
				year: 2026,
				month: 11,
				day: 17,
				hour: 21,
				minute: 0
			)
		)!,
		title: "convo added manually",
		messages: [
			Message(role: .user, model: fakeModels[5], content: "Convo 6"),
			Message(role: .assistant, model: fakeModels[5], content: "Hi again!"),
		]
	),
	Conversation(
		createdAt: Calendar.current.date(
			from: DateComponents(
				year: 2026,
				month: 11,
				day: 17,
				hour: 21,
				minute: 0
			)
		)!,
		updatedAt: Calendar.current.date(
			from: DateComponents(
				year: 2026,
				month: 11,
				day: 17,
				hour: 21,
				minute: 0
			)
		)!,
		title: "last convo",
		messages: [
			Message(role: .user, model: fakeModels[6], content: "Convo 7"),
			Message(
				role: .assistant,
				model: fakeModels[6],
				content: """
					# Hi again!

					> Multiline reply

					!!!!!!  
					lalalala
					"""

			),
		]
	),
	Conversation(
		createdAt: Calendar.current.date(
			from: DateComponents(
				year: 2026,
				month: 11,
				day: 17,
				hour: 21,
				minute: 0
			)
		)!,
		updatedAt: Calendar.current.date(
			from: DateComponents(
				year: 2026,
				month: 11,
				day: 17,
				hour: 21,
				minute: 0
			)
		)!,
		title: "joking - not last",
		messages: [
			Message(role: .user, model: fakeModels[7], content: "Convo 8"),
			Message(role: .assistant, model: fakeModels[7], content: "Hi again!"),
		]
	),
	Conversation(
		createdAt: Calendar.current.date(
			from: DateComponents(
				year: 2026,
				month: 11,
				day: 17,
				hour: 21,
				minute: 0
			)
		)!,
		updatedAt: Calendar.current.date(
			from: DateComponents(
				year: 2026,
				month: 11,
				day: 17,
				hour: 21,
				minute: 0
			)
		)!,
		title: "lol",
		messages: [
			Message(role: .user, model: fakeModels[8], content: "Convo 9"),
			Message(role: .assistant, model: fakeModels[8], content: "Hi again!"),
		]
	),
	Conversation(
		createdAt: Calendar.current.date(
			from: DateComponents(
				year: 2026,
				month: 11,
				day: 17,
				hour: 21,
				minute: 0
			)
		)!,
		updatedAt: Calendar.current.date(
			from: DateComponents(
				year: 2026,
				month: 11,
				day: 17,
				hour: 21,
				minute: 0
			)
		)!,
		title: "last convo added manually",
		messages: [
			Message(role: .user, model: fakeModels[9], content: "Convo 10"),
			Message(
				role: .assistant,
				model: fakeModels[9],
				content: "Hi again!"
			),
		]
	),
]

let fakeModels: [LocalModel] = [
	LocalModel(id: "openAI", alias: "openAi"),
	LocalModel(id: "claude", alias: "claude"),
	LocalModel(id: "deepseek", alias: "deepseek"),
	LocalModel(id: "qwen", alias: "qwen"),
	LocalModel(id: "muse", alias: "muse"),
	LocalModel(id: "grok", alias: "grok"),
	LocalModel(id: "gemini", alias: "gemini"),
	LocalModel(id: "opus", alias: "opus"),
	LocalModel(id: "mistral", alias: "mistral"),
	LocalModel(
		id: "mlx-community/Qwen3.8-27B-OptiQ-4bit",
		alias: "qwen3.8-27B-OptiQ-4bit"
	),
]
