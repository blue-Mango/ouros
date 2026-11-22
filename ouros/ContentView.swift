//
//  ContentView.swift
//  ouros
//
//  Created by Mischa McLaughlin on 15/11/2026.
//

import SwiftUI

struct ContentView: View {
	@State private var conversations: [Conversation]
	@State private var conversationId: UUID?
	@State private var streamingMessageID: UUID?

	@State private var models: [LocalModel] = []
	@State private var selectedModel: String?
	@State private var reasoningEffort: String?
	@State private var isThinkingEnabled: Bool = false

	@State private var isSidebarOpen: Bool = true
	@State private var isSending: Bool = false

	@State private var draft: String = ""
	@State private var chatError: String?

	init(
		previewConvos: [Conversation] = [],
		previewModels: [LocalModel] = [],
		previewSelectedModel: String = ""
	) {
		_conversations = State(initialValue: previewConvos)
		_models = State(initialValue: previewModels)
		_selectedModel = State(initialValue: previewSelectedModel)
	}

	private var selectedConversation: Conversation? {
		conversations.first { $0.id == conversationId }
	}

	var body: some View {
		HSplitView {
			Sidebar(
				conversationId: $conversationId,
				isSidebarOpen: isSidebarOpen,
				isSending: isSending,
				conversations: conversations,
			)

			Canvas(
				draft: $draft,
				chatError: $chatError,
				isSending: isSending,
				streamingMessageID: streamingMessageID,
				selectedConversation: selectedConversation,
				onExpandMessage: expandMessage,
				onSend: { send() },
			)
		}
		.frame(minWidth: 600, minHeight: 400)
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.overlay(alignment: .top) {
			Divider()
		}
		.toolbar {
			ToolBarItems(
				isSidebarOpen: $isSidebarOpen,
				isSending: $isSending,
				isThinkingEnabled: $isThinkingEnabled,
				reasoningEffort: $reasoningEffort,
				selectedModel: $selectedModel,
				chatError: $chatError,
				draft: $draft,
				conversationId: $conversationId,
				models: models,
			)
		}
		.toolbarBackground(
			Color(.backgroundBase),
			for: .windowToolbar
		)
		.toolbarBackgroundVisibility(.visible, for: .windowToolbar)
		.navigationTitle(selectedConversation?.title ?? "New chat")
		.presentedWindowToolbarStyle(.unifiedCompact)
		.task {
			do {
				models = try await MLXClient().fetchModels()
			} catch {
				print("MLX error:", error)
			}
		}
	}

	private func expandMessage(_ messageId: UUID, _ isExpanded: Bool) {
		guard
			let convoIndex = conversations.firstIndex(where: {
				$0.id == conversationId
			}),
			let messageIndex = conversations[convoIndex].messages.firstIndex(where: {
				$0.id == messageId
			}),
			conversations[convoIndex].messages[messageIndex].role
				== .assistant
		else { return }

		conversations[convoIndex].messages[messageIndex]
			.setIsExpanded(isExpanded)
	}

	private func send() {
		guard !isSending else { return }

		let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !text.isEmpty else { return }

		guard
			let model = selectedModel?.trimmingCharacters(
				in: .whitespacesAndNewlines
			), !model.isEmpty
		else {
			chatError = "Select a model first."

			return
		}

		chatError = nil
		draft = ""

		if !conversations.contains(where: { $0.id == conversationId }) {
			let conversation = Conversation(
				createdAt: .now,
				updatedAt: .now,
				title: text.count >= 50 ? "\(text.prefix(47))..." : text,
				messages: []
			)

			conversations.append(conversation)
			conversationId = conversation.id
		}

		guard let conversationId,
			let index = conversations.firstIndex(where: { $0.id == conversationId })
		else { return }

		conversations[index].messages.append(
			Message(role: .user, model: selectedModel ?? "", content: text)
		)

		let requestMessages = conversations[index].messages
		let assistantMessage = Message(
			role: .assistant,
			model: selectedModel ?? "",
			content: ""
		)
		let assistantId = assistantMessage.id
		conversations[index].messages.append(assistantMessage)

		conversations[index].updatedAt = .now

		streamingMessageID = assistantId
		isSending = true

		Task { @MainActor in
			defer {
				streamingMessageID = nil
				isSending = false
			}

			do {
				_ = try await MLXClient().chat(
					model: model,
					messages: requestMessages,
					reasoningEffort: reasoningEffort,
					enableThinking: isThinkingEnabled,
					onReasoning: { chunk in
						guard
							let convoIndex = conversations.firstIndex(
								where: { $0.id == conversationId }
							),
							let messageIndex = conversations[convoIndex].messages
								.firstIndex(
									where: { $0.id == assistantId }
								)
						else { return }

						if conversations[convoIndex].messages[messageIndex].role
							== .assistant
						{
							conversations[convoIndex].messages[messageIndex].setIsExpanded(
								true
							)
						}

						conversations[convoIndex].messages[messageIndex].reasoning +=
							chunk
					},
					onChunk: { chunk in
						guard
							let convoIndex = conversations.firstIndex(
								where: { $0.id == conversationId }
							),
							let messageIndex = conversations[convoIndex].messages
								.firstIndex(
									where: { $0.id == assistantId }
								)
						else { return }

						if conversations[convoIndex].messages[messageIndex].role
							== .assistant
						{
							conversations[convoIndex].messages[messageIndex].setIsExpanded(
								false
							)
						}

						conversations[convoIndex].messages[messageIndex].content +=
							chunk
					},
				)
			} catch {
				chatError = "Couldn’t get a reply"

				if let conversationIndex = conversations.firstIndex(where: {
					$0.id == conversationId
				}),
					let messageIndex = conversations[conversationIndex].messages
						.firstIndex(
							where: { $0.id == assistantId }
						),
					conversations[conversationIndex].messages[messageIndex].content
						.isEmpty
				{
					conversations[conversationIndex].messages.remove(at: messageIndex)
				}
			}
		}
	}
}

#Preview {
	ContentView(
		previewConvos: [
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
					Message(role: .user, model: "openAi", content: "Hello"),
					Message(role: .assistant, model: "openAi", content: "Hi there!"),
					Message(role: .user, model: "openAi", content: "How you doing?!"),
					Message(role: .assistant, model: "openAi", content: "Convo1!"),
				],
			),
			Conversation(
				createdAt: .now,
				updatedAt: .now,
				title: "Another new convo",
				messages: [
					Message(role: .user, model: "openAi", content: "Convo2"),
					Message(role: .assistant, model: "openAi", content: "Hi there!"),
					Message(role: .user, model: "openAi", content: "How you doing?!"),
					Message(role: .assistant, model: "openAi", content: "Chillllaxing!"),
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
					Message(role: .user, model: "openAi", content: "Hello"),
					Message(role: .assistant, model: "openAi", content: "Convo3"),
					Message(role: .user, model: "openAi", content: "How you doing?!"),
					Message(role: .assistant, model: "openAi", content: "noice"),
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
					Message(role: .user, model: "claude", content: "Convo4"),
					Message(role: .assistant, model: "claude", content: "Hi there!"),
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
					Message(role: .user, model: "deepseek", content: "Convo 5"),
					Message(role: .assistant, model: "deepseek", content: "Hi again!"),
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
					Message(role: .user, model: "deepseek", content: "Convo 6"),
					Message(role: .assistant, model: "deepseek", content: "Hi again!"),
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
					Message(role: .user, model: "qwen", content: "Convo 7"),
					Message(
						role: .assistant,
						model: "claude",
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
					Message(role: .user, model: "qwen", content: "Convo 8"),
					Message(role: .assistant, model: "qwen", content: "Hi again!"),
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
					Message(role: .user, model: "qwen", content: "Convo 9"),
					Message(role: .assistant, model: "qwen", content: "Hi again!"),
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
					Message(role: .user, model: "openAI", content: "Convo 10"),
					Message(role: .assistant, model: "openAI", content: "Hi again!"),
				]
			),
		],
		previewModels: [
			LocalModel(id: "openAI"),
			LocalModel(id: "claude"),
			LocalModel(id: "deepseek"),
		],
		previewSelectedModel: "openAI"
	)
}
