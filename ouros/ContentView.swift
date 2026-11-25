//
//  ContentView.swift
//  ouros
//
//  Created by Mischa McLaughlin on 15/11/2026.
//

import SwiftData
import SwiftUI

struct ContentView: View {
	@Binding var models: [LocalModel]

	@State private var replyTask: Task<Void, Never>?

	@Environment(\.modelContext) private var modelContext
	@Query(sort: \Conversation.updatedAt, order: .reverse)
	private var conversations: [Conversation]

	@State private var conversationId: UUID?

	@State private var draft: String = ""
	@State private var reasoningEffort: String?
	@State private var isThinkingEnabled: Bool = false
	@State private var isSending: Bool = false
	@State private var streamingMessageID: UUID?
	@State private var chatError: String?

	@State private var selectedModelID: LocalModel.ID?

	@State private var isSidebarOpen: Bool = true

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
				selectedModelID: $selectedModelID,
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
				onStop: { replyTask?.cancel() },
			)
		}
		.frame(minWidth: 600, minHeight: 400)
		.frame(maxWidth: .infinity, maxHeight: .infinity)
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

		conversations[convoIndex].messages[messageIndex]
			.setIsExpanded(isExpanded ? true : nil)
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

		let conversation: Conversation

		if let existing = selectedConversation {
			conversation = existing
		} else {
			conversation = Conversation(
				updatedAt: .now,
				title: text.count >= 50 ? "\(text.prefix(47))..." : text,
				messages: []
			)
			modelContext.insert(conversation)
			conversationId = conversation.id
		}

		conversation.appendMessage(
			Message(role: .user, model: model, content: text)
		)

		let requestMessages = conversation.orderedMessages
		let assistantMessage = Message(
			role: .assistant,
			model: model,
			content: ""
		)
		conversation.appendMessage(assistantMessage)

		conversation.updatedAt = .now
		streamingMessageID = assistantMessage.id
		isSending = true

		replyTask = Task { @MainActor in
			defer {
				if assistantMessage.content.isEmpty {
					conversation.messages.removeAll { $0.id == assistantMessage.id }
					modelContext.delete(assistantMessage)
				}
				replyTask = nil
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
						if assistantMessage.reasoning.isEmpty,
							assistantMessage.content.isEmpty,
							assistantMessage.isExpanded != nil
						{
							assistantMessage.setIsExpanded(true)
						}
						assistantMessage.reasoning += chunk
					},
					onChunk: { chunk in
						if assistantMessage.content.isEmpty {
							assistantMessage.setIsExpanded(false)
						}
						assistantMessage.content += chunk
					},
				)
			} catch {
				if !Task.isCancelled, conversationId == conversation.id {
					chatError = "Couldn’t get a reply"
				}
			}
		}
	}
}
