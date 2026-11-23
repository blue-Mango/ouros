//
//  ContentView.swift
//  ouros
//
//  Created by Mischa McLaughlin on 15/11/2026.
//

import SwiftUI

struct ContentView: View {
	@Binding var models: [LocalModel]

	@State private var conversations: [Conversation] = fakeConversations
	@State private var conversationId: UUID?
	@State private var streamingMessageID: UUID?

	@State private var reasoningEffort: String?
	@State private var isThinkingEnabled: Bool = false

	@State private var isSidebarOpen: Bool = true
	@State private var isSending: Bool = false

	@State private var draft: String = ""
	@State private var chatError: String?

	@State private var selectedModelID: LocalModel.ID?

	private var selectedModel: LocalModel? {
		models.first { $0.id == selectedModelID }
	}

	private var selectedConversation: Conversation? {
		conversations.first { $0.id == conversationId }
	}

	var body: some View {
		HSplitView {
			Sidebar(
				conversationId: $conversationId,
				streamingMessageID: $streamingMessageID,
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
				selectedModelId: $selectedModelID,
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

		var message = conversations[convoIndex].messages[messageIndex]

		if message.isExpanded == true {
			message.setIsExpanded(nil)
		} else {
			message.setIsExpanded(true)
		}
	}

	private func send() {
		guard !isSending else { return }

		let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !text.isEmpty else { return }

		guard
			let model = selectedModel, !model.id.isEmpty
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
			Message(role: .user, model: model, content: text)
		)

		let requestMessages = conversations[index].messages
		let assistantMessage = Message(
			role: .assistant,
			model: model,
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
					model: model.id,
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
							&& conversations[convoIndex].messages[messageIndex].isExpanded
								!= nil
						{
							conversations[convoIndex].messages[messageIndex]
								.setIsExpanded(true)
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

						if conversations[convoIndex].messages[messageIndex].content.isEmpty
						{
							conversations[convoIndex].messages[messageIndex]
								.setIsExpanded(false)
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
