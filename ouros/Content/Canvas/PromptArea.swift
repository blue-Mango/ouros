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

	var body: some View {
		HStack(spacing: 0) {
			TextField("Message...", text: $draft, axis: .vertical)
				.textInputStyle()
				.onSubmit { onSend() }

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
		}
		.overlay(alignment: .top) {
			Divider()
		}
	}
}
