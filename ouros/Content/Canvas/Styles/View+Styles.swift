//
//  View+Styles.swift
//  ouros
//
//  Created by Mischa McLaughlin on 21/11/2026.
//

import SwiftUI

extension View {
	// Style
	func newChatStyle() -> some View {
		self
			.fontTitleStyle()
			.multilineTextAlignment(.center)
	}

	func textInputStyle() -> some View {
		self
			.lineLimit(1...6)
			.textFieldStyle(.plain)
			.foregroundStyle(Color.textPrimary)
			.padding()
			.overlay(alignment: .trailing) {
				Rectangle()
					.fill(Color(.separatorColour))
					.frame(width: 1)
					.allowsHitTesting(false)
			}
	}

	func fontTitleStyle() -> some View {
		self
			.fontTitleSize()
			.fontWeightStyle()
	}

	func fontSubTitleStyle() -> some View {
		self
			.fontSubTitleSize()
			.fontWeightStyle()
	}

	func fontConversationStyle(isUser: Bool, message: Message) -> some View {
		self
			.textSelection(.enabled)
			.fontConversationSize()
			.fontWeightStyle()
			.fontLineSpacingStyle()
			.fontLetterSpacingStyle()
			.background {
				Rectangle()
					.fill(isUser ? .backgroundBase : .clear)
			}
			.overlay {
				Rectangle()
					.stroke(
						isUser ? .separatorColour : .clear,
						lineWidth: 1
					)
			}
			.frame(
				maxWidth: .infinity,
				alignment: message.role == .user ? .trailing : .leading
			)
	}

	func fontConversationReasoningStyle() -> some View {
		self
			.textSelection(.enabled)
			.fontConversationSize()
			.fontWeightStyle()
			.fontSecondaryColour()
	}

	func fontInfoStyle() -> some View {
		self
			.fontInfoSize()
			.fontWeightStyle()
			.fontSecondaryColour()
	}

	func conversationTileStyle(
		convo: Conversation,
		conversationId: UUID?,
		hoverId: UUID?
	) -> some View {
		self
			.padding(16)
			.background(
				conversationId == convo.id
					? Color(.backgroundCanvas)
					: hoverId == convo.id
						? Color(nsColor: .hover) : .backgroundBase,
				in: Rectangle()
			)
			.overlay(alignment: .leading) {
				if conversationId == convo.id {
					Rectangle()
						.fill(.hover)
						.frame(width: 8)
						.clipped()
						.allowsHitTesting(false)
				}
			}
			.animationEaseOut(isAnimated: hoverId == convo.id)
			.animationEaseOut(isAnimated: conversationId == convo.id)
			.contentShape(Rectangle())
	}

	func errorIconStyle(isHovering: Bool) -> some View {
		self
			.fontTitleStyle()
			.foregroundStyle(isHovering ? Color.textPrimary : .accent)
			.animationEaseOut(isAnimated: isHovering)
	}

	func errorMessageStyle(isHovering: Bool) -> some View {
		self
			.animationEaseOut(isAnimated: isHovering)
			.padding(.vertical, 4)
			.overlay(alignment: .bottom) {
				Rectangle()
					.fill(isHovering ? Color.textPrimary : .accent)
					.frame(height: 1)
			}
	}

	// Spacing
	private func fontLineSpacingStyle() -> some View {
		self.lineSpacing(4)
	}

	private func fontLetterSpacingStyle() -> some View {
		self.tracking(0.75)
	}

	// Weight
	private func fontWeightStyle() -> some View {
		self.fontWeight(.thin)
	}

	// Size
	private func fontTitleSize() -> some View {
		self.font(.system(size: 24))
	}

	private func fontSubTitleSize() -> some View {
		self.font(.system(size: 16))
	}

	private func fontConversationSize() -> some View {
		self.font(.system(size: 13))
	}

	private func fontInfoSize() -> some View {
		self.font(.system(size: 12))
	}

	// Colour
	private func fontSecondaryColour() -> some View {
		self.foregroundStyle(.textSecondary)
	}

	// Animation
	private func animationEaseOut(isAnimated: Bool) -> some View {
		self
			.animation(
				.easeOut(duration: 0.1),
				value: isAnimated
			)
	}
}
