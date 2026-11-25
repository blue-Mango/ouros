//
//  PromptArea.swift
//  ouros
//
//  Created by Mischa McLaughlin on 21/11/2026.
//

import SwiftUI

struct PromptArea: View {
	@Binding var chatError: String?
	@Binding var draft: String

	let isSending: Bool
	let selectedConversation: Conversation?
	let onSend: () -> Void
	let onStop: () -> Void

	var body: some View {
		HStack(spacing: 0) {
			TextField("Message...", text: $draft, axis: .vertical)
				.textInputStyle()
				.onSubmit { onSend() }

			Button {
				isSending ? onStop() : onSend()
			} label: {
				Image(systemName: isSending ? "stop.fill" : "arrow.up")
					.padding()
					.contentShape(Rectangle())
			}
			.buttonStyle(.plain)
			.disabled(
				!isSending
					&& draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
			)
			.accessibilityLabel(isSending ? "Stop generating" : "Send message")
		}
		.overlay(alignment: .top) {
			Divider()
		}
	}
}
