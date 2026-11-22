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
		.onScrollPhaseChange { _, phase in
			scrollPhase = phase
		}
		.onScrollGeometryChange(for: ScrollGeometry.self, of: { $0 }) {
			before,
			after in
			let distanceFromBottom =
				before.contentSize.height
				+ before.contentInsets.bottom - before.visibleRect.maxY

			if scrollPhase == .idle,
				after.contentSize.height > before.contentSize.height,
				distanceFromBottom <= 12
			{
				scrollPosition.scrollTo(edge: .bottom)
			}
		}
	}
}
