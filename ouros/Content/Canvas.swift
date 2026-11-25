//
//  Canvas.swift
//  ouros
//
//  Created by Mischa McLaughlin on 21/11/2026.
//

import SwiftUI

struct Canvas: View {
	@Binding var draft: String
	@Binding var chatError: String?

	let isSending: Bool
	let streamingMessageID: UUID?
	let selectedConversation: Conversation?

	let onExpandMessage: (UUID, Bool) -> Void
	let onSend: () -> Void
	let onStop: () -> Void

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
				onSend: { onSend() },
				onStop: { onStop() }
			)
		}
		.background(.backgroundCanvas)
		.frame(minWidth: 220)
	}
}
