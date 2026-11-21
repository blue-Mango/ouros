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
			Color(nsColor: .windowBackgroundColor),
			for: .windowToolbar
		)
		.toolbarBackgroundVisibility(.visible, for: .automatic)
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

		conversations[index].messages.append(Message(role: .user, content: text))

		let requestMessages = conversations[index].messages
		let assistantMessage = Message(role: .assistant, content: "")
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

private struct ToolBarItems: ToolbarContent {
	@Binding var isSidebarOpen: Bool
	@Binding var isSending: Bool
	@Binding var isThinkingEnabled: Bool
	@Binding var reasoningEffort: String?
	@Binding var selectedModel: String?
	@Binding var chatError: String?
	@Binding var draft: String
	@Binding var conversationId: UUID?

	var models: [LocalModel]

	var body: some ToolbarContent {
		ToolbarItem(placement: .navigation) {
			Button {
				isSidebarOpen.toggle()
			} label: {
				Label("Open sidebar", systemImage: "sidebar.leading")
					.font(.system(size: 12, weight: .thin))
			}
			.buttonStyle(.accessoryBarAction)
			.help("Open sidebar")
		}
		.sharedBackgroundVisibility(.hidden)

		ToolbarSpacer(.flexible, placement: .automatic)

		if isThinkingEnabled {
			ToolbarItem(placement: .automatic) {
				Picker("Reasoning effort", selection: $reasoningEffort) {
					ForEach(["low", "medium", "xhigh"], id: \.self) { effort in
						Text(effort == "xhigh" ? "Extra high" : effort.capitalized)
							.tag(effort)
							.font(.system(size: 12, weight: .thin))
					}
				}
			}
			.sharedBackgroundVisibility(.hidden)
		}

		ToolbarItem(placement: .automatic) {
			Button {
				isThinkingEnabled = !isThinkingEnabled
				reasoningEffort = reasoningEffort ?? "low"
			} label: {
				Label(
					"Thinking",
					systemImage: isThinkingEnabled ? "brain.fill" : "brain"
				)
				.font(.system(size: 12, weight: .thin))
			}
			.buttonStyle(.accessoryBarAction)
			.help(isThinkingEnabled ? "Thinking on" : "Thinking off")
			.disabled(isSending)
		}
		.sharedBackgroundVisibility(.hidden)

		ToolbarItem(placement: .automatic) {
			Menu {
				if models.count > 0 {
					ForEach(models) { model in
						Button(model.name) {
							selectedModel = model.id
						}
						.buttonStyle(.accessoryBarAction)
					}
				} else {
					Text("No models available, add some to get started.")
						.font(.system(size: 12, weight: .thin))
				}
			} label: {
				HStack(spacing: 8) {
					Image(systemName: "cpu")
						.font(.system(size: 12, weight: .thin))
					Text(selectedModel ?? "Choose model")
						.font(.system(size: 12, weight: .thin))
				}
			}
		}
		.sharedBackgroundVisibility(.hidden)

		ToolbarItem(placement: .automatic) {
			HStack {
				Divider()
					.frame(height: 16)
			}
			.accessibilityHidden(true)
		}
		.sharedBackgroundVisibility(.hidden)

		ToolbarItem(placement: .automatic) {
			Button {
				draft = ""
				chatError = nil
				conversationId = nil
			} label: {
				Label("New chat", systemImage: "square.and.pencil")
					.font(.system(size: 12, weight: .thin))
			}
			.buttonStyle(.accessoryBarAction)
			.help("New chat")
			.disabled(isSending)
		}
		.sharedBackgroundVisibility(.hidden)
	}
}

private struct Sidebar: View {
	@Binding var conversationId: UUID?

	let isSidebarOpen: Bool
	let isSending: Bool
	let conversations: [Conversation]

	@State private var hoveredId: UUID?

	var body: some View {

		if isSidebarOpen {
			ScrollView {
				LazyVStack(spacing: 0) {
					ForEach(conversations.reversed()) { convo in
						VStack(spacing: 0) {
							Button {
								conversationId = convo.id
							} label: {
								VStack {
									Text(convo.title)
										.font(.system(size: 24, weight: .thin))
										.frame(maxWidth: .infinity, alignment: .leading)

									HStack {
										Text(
											convo.updatedAt.formatted(
												date: .abbreviated,
												time: .shortened
											)
										)
										.font(.system(size: 12, weight: .thin))
										.foregroundStyle(.gray)
										.frame(maxWidth: .infinity, alignment: .leading)

										if isSending {
											Spacer()

											Text("Working")
												.font(.system(size: 12, weight: .thin))
												.foregroundStyle(.gray)
												.frame(maxWidth: .infinity, alignment: .trailing)
										}
									}
									.frame(maxWidth: .infinity, alignment: .leading)
								}
								.frame(maxWidth: .infinity, alignment: .leading)
								.padding(.horizontal, 8)
								.padding(.vertical, 8)
								.background(
									conversationId == convo.id
										? Color(.active)
										: hoveredId == convo.id
											? Color(nsColor: .hover).opacity(0.5) : .clear,
									in: RoundedRectangle(cornerRadius: 4)
								)
								.animation(
									.easeOut(duration: 0.1),
									value: hoveredId == convo.id,
								)
								.animation(
									.easeOut(duration: 0.1),
									value: conversationId == convo.id
								)
								.contentShape(Rectangle())
								.onHover { hovering in
									hoveredId = hovering ? convo.id : nil

									if hovering {
										NSCursor.pointingHand.push()
									} else {
										NSCursor.pop()
									}
								}
							}
							.buttonStyle(.plain)
							.padding(8)

							if convo.id != conversations.first?.id {
								Divider()
							}
						}
					}
				}
				.frame(maxWidth: .infinity)
			}
			.frame(
				minWidth: 220,
				idealWidth: 250,
				maxHeight: .infinity,
				alignment: .leading
			)
		}

	}
}

private struct Canvas: View {
	@Binding var draft: String
	@Binding var chatError: String?

	let isSending: Bool
	let streamingMessageID: UUID?
	let selectedConversation: Conversation?

	let onExpandMessage: (UUID, Bool) -> Void
	let onSend: () -> Void

	var body: some View {
		VStack {
			ContentArea(
				chatError: $chatError,
				isSending: isSending,
				streamingMessageID: streamingMessageID,
				selectedConversation: selectedConversation,
				onExpandMessage: onExpandMessage
			)

			PromptArea(
				chatError: $chatError,
				draft: $draft,
				isSending: isSending,
				selectedConversation: selectedConversation,
				onSend: { onSend() }
			)
		}
		.frame(minWidth: 220)
	}
}

private struct ContentArea: View {
	@Binding var chatError: String?

	let isSending: Bool
	let streamingMessageID: UUID?
	let selectedConversation: Conversation?
	let onExpandMessage: (UUID, Bool) -> Void

	var body: some View {
		ScrollView {
			LazyVStack(spacing: 0) {
				if let convo = selectedConversation {
					ForEach(convo.messages) { message in
						MessageRow(
							message: message,
							isStreaming: message.id == streamingMessageID,
							onExpandMessage: onExpandMessage
						)
					}
				}
			}
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.overlay {
			if selectedConversation?.messages.isEmpty ?? true {
				Text("Hey there,\nWhat do you want to work on today?")
					.font(.system(size: 24, weight: .thin))
					.foregroundStyle(.gray)
					.multilineTextAlignment(.center)
					.frame(
						maxWidth: .infinity,
						maxHeight: .infinity,
						alignment: .center
					)
			}
		}
		.overlay(alignment: .bottom) {
			ErrorBanner(chatError: $chatError)
		}
	}
}

private struct MessageRow: View {
	let message: Message
	let isStreaming: Bool
	let onExpandMessage: (UUID, Bool) -> Void

	private var isUser: Bool { message.role == .user }

	var body: some View {
		LazyVStack {
			if !message.reasoning.isEmpty {
				DisclosureGroup(
					isExpanded: Binding(
						get: { message.isExpanded ?? false },
						set: { isExpanded in
							onExpandMessage(message.id, isExpanded)
						}

					)
				) {
					Text(message.reasoning)
						.textSelection(.enabled)
						.foregroundStyle(.secondary)
						.font(.system(size: 13, weight: .thin))
						.frame(maxWidth: .infinity, alignment: .leading)
						.padding(.horizontal, 12)
						.padding(.top, 12)
				} label: {
					HStack {
						if message.isExpanded ?? false {
							Image(systemName: "sparkles")
								.phaseAnimator([Color.secondary, .primary]) {
									icon,
									colour in
									icon.foregroundStyle(colour)
								} animation: { _ in
									.easeInOut(duration: 1)
								}
						} else {
							Image(systemName: "sparkles")
								.foregroundStyle(.secondary)
								.font(.system(size: 13, weight: .thin))
						}
						Text("Thinking")
							.foregroundStyle(.secondary)
							.font(.system(size: 13, weight: .thin))
					}
				}
				.disclosureGroupStyle(.automatic)
				.frame(maxWidth: .infinity, alignment: .leading)
			}

			Group {
				MarkdownTextOutput(source: message.content, isStreaming: isStreaming)
			}
			.textSelection(.enabled)
			.font(.system(size: 13, weight: .thin))
			.padding(12)
			.background {
				RoundedRectangle(cornerRadius: 8)
					.fill(isUser ? Color(nsColor: .windowBackgroundColor) : .clear)
			}
			.overlay {
				RoundedRectangle(cornerRadius: 8)
					.stroke(
						isUser ? Color(nsColor: .separatorColor) : .clear,
						lineWidth: 1
					)
			}
			.frame(
				maxWidth: .infinity,
				alignment: message.role == .user
					? .trailing : .leading
			)
		}
		.padding(12)
	}
}

private struct PromptArea: View {
	@Binding var chatError: String?
	@Binding var draft: String

	let isSending: Bool
	let selectedConversation: Conversation?
	let onSend: () -> Void

	var body: some View {
		HStack {
			TextField("Message...", text: $draft, axis: .vertical)
				.lineLimit(1...6)
				.textFieldStyle(.plain)
				.foregroundStyle(Color.primary)
				.padding()
				.onSubmit {
					onSend()
				}

			Button {
				onSend()
			} label: {
				Image(systemName: "arrow.up")
					.padding()
					.contentShape(Rectangle())
			}
			.buttonStyle(.plain)
			.disabled(
				isSending
					|| draft.trimmingCharacters(
						in: .whitespacesAndNewlines
					).isEmpty
			)
			.accessibilityLabel("Send message")
			.overlay(alignment: .leading) {
				Rectangle()
					.fill(Color(nsColor: .separatorColor))
					.frame(width: 1)
					.allowsHitTesting(false)
			}
		}
		.overlay(alignment: .top) {
			Divider()
		}
	}
}

private struct ErrorBanner: View {
	@Binding var chatError: String?

	@State private var isHovering = false

	var body: some View {
		if let error = chatError {
			HStack(spacing: 4) {
				Button {
					chatError = nil
				} label: {
					Label("Close error", systemImage: "xmark.square")
						.font(.system(size: 24, weight: .thin))
						.foregroundStyle(isHovering ? Color.primary : .red)
						.animation(
							.easeOut(duration: 0.1),
							value: isHovering
						)
						.contentShape(Rectangle())
						.onHover { hovering in
							isHovering = hovering
						}
				}
				.buttonStyle(.plain)
				.labelStyle(.iconOnly)
				.help("Close error")

				VStack {
					Text(error)
						.animation(
							.easeOut(duration: 0.1),
							value: isHovering
						)
						.frame(maxWidth: .infinity, alignment: .leading)
						.padding(.vertical, 4)
						.overlay(alignment: .bottom) {
							Rectangle()
								.fill(isHovering ? Color.primary : .red)
								.frame(height: 1)
						}
				}
			}
			.frame(maxWidth: .infinity, alignment: .bottomLeading)
			.padding()
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
					Message(role: .user, content: "Hello"),
					Message(role: .assistant, content: "Hi there!"),
					Message(role: .user, content: "How you doing?!"),
					Message(role: .assistant, content: "Convo1!"),
				],
			),
			Conversation(
				createdAt: .now,
				updatedAt: .now,
				title: "Another new convo",
				messages: [
					Message(role: .user, content: "Convo2"),
					Message(role: .assistant, content: "Hi there!"),
					Message(role: .user, content: "How you doing?!"),
					Message(role: .assistant, content: "Chillllaxing!"),
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
					Message(role: .user, content: "Hello"),
					Message(role: .assistant, content: "Convo3"),
					Message(role: .user, content: "How you doing?!"),
					Message(role: .assistant, content: "noice"),
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
					Message(role: .user, content: "Convo4"),
					Message(role: .assistant, content: "Hi there!"),
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
					Message(role: .user, content: "Convo 5"),
					Message(role: .assistant, content: "Hi again!"),
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
					Message(role: .user, content: "Convo 6"),
					Message(role: .assistant, content: "Hi again!"),
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
					Message(role: .user, content: "Convo 7"),
					Message(role: .assistant, content: "Hi again!"),
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
					Message(role: .user, content: "Convo 8"),
					Message(role: .assistant, content: "Hi again!"),
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
					Message(role: .user, content: "Convo 9"),
					Message(role: .assistant, content: "Hi again!"),
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
					Message(role: .user, content: "Convo 10"),
					Message(role: .assistant, content: "Hi again!"),
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
