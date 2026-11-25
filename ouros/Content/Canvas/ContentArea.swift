//
//  ContentArea.swift
//  ouros
//
//  Created by Mischa McLaughlin on 21/11/2026.
//

import SwiftUI

struct ContentArea: View {
	@Binding var chatError: String?
	@State private var scrollPosition = ScrollPosition(edge: .bottom)
	@State private var scrollPhase: ScrollPhase = .idle

	let isSending: Bool
	let streamingMessageID: UUID?
	let selectedConversation: Conversation?
	let onExpandMessage: (UUID, Bool) -> Void

	var body: some View {
		ScrollView {
			LazyVStack(spacing: 0) {
				if let convo = selectedConversation {
					ForEach(convo.orderedMessages) { message in
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
					.newChatStyle()
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
		.scrollPosition($scrollPosition)
		.task(id: selectedConversation?.id) {
			scrollPosition.scrollTo(edge: .bottom)
		}
	}
}
