//
//  MessageRow.swift
//  ouros
//
//  Created by Mischa McLaughlin on 21/11/2026.
//

import SwiftUI

struct MessageRow: View {
	let message: Message
	let isStreaming: Bool
	let onExpandMessage: (UUID, Bool) -> Void

	private var isUser: Bool { message.role == .user }

	var body: some View {
		LazyVStack {
			if !message.reasoning.isEmpty {
				let isExpanded = message.isExpanded ?? false

				Button {
					onExpandMessage(message.id, !(message.isExpanded ?? false))
				} label: {
					HStack {

						if isExpanded {
							Image(systemName: "sparkles")
								.phaseAnimator([Color.textSecondary, .textPrimary]) {
									icon,
									colour in
									icon.foregroundStyle(colour)
								} animation: { _ in
									.easeInOut(duration: 1)
								}
						} else {
							Image(systemName: "sparkles")
						}
						Text("Thinking")
						Image(
							systemName: isExpanded ? "chevron.down" : "chevron.forward"
						)
					}
					.frame(maxWidth: .infinity, alignment: .leading)
					.fontConversationReasoningStyle()
				}
				.buttonStyle(.plain)

				if isExpanded {
					Text(message.reasoning)
						.fontConversationReasoningStyle()
						.frame(maxWidth: .infinity, alignment: .leading)
						.padding(.horizontal, 12)
						.padding(.top, 12)
				}
			}

			Group {
				MarkdownTextOutput(source: message.content, isStreaming: isStreaming)
			}
			.padding(12)
			.fontConversationStyle(isUser: isUser, message: message)
		}
		.padding(12)
	}
}
