//
//  Sidebar.swift
//  ouros
//
//  Created by Mischa McLaughlin on 21/11/2026.
//

import SwiftUI

struct Sidebar: View {
	@Binding var conversationId: UUID?
	@Binding var streamingMessageID: UUID?

	let isSidebarOpen: Bool
	let isSending: Bool
	let conversations: [Conversation]

	@State private var hoverId: UUID?

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
										.fontTitleStyle()
										.frame(maxWidth: .infinity, alignment: .leading)

									HStack(alignment: .top, spacing: 8) {
										Text(
											convo.updatedAt.formatted(
												date: .abbreviated,
												time: .shortened
											)
										)

										Divider()

										if let model = convo.messages.last?.model {
											Text(verbatim: model.alias)
										}

										Divider()

										if isSending
											&& convo.messages.last?.id == streamingMessageID
										{
											Spacer()

											let pieces: [(symbol: String, angle: Double)] = [
												("puzzlepiece", 0),
												("puzzlepiece.extension", 90),
												("puzzlepiece", 180),
												("puzzlepiece.extension", -90),
											]

											PhaseAnimator(pieces.indices) { phase in
												ZStack {
													ForEach(pieces.indices, id: \.self) { index in
														Image(systemName: pieces[index].symbol)
															.padding(2)
															.rotationEffect(.degrees(pieces[index].angle))
															.opacity(index == phase ? 1 : 0)
															.foregroundStyle(.accent)
													}
												}
											} animation: { _ in
												.easeInOut(duration: 1)
											}
											.frame(alignment: .trailing)
										} else {
											Spacer()

											Image(systemName: "puzzlepiece")
												.hidden()
												.overlay {
													Image("PuzzleComplete")
														.foregroundStyle(.textSecondary)
												}
												.padding(2)
												.frame(alignment: .trailing)
										}
									}
									.frame(maxWidth: .infinity, alignment: .leading)
									.fontInfoStyle()
								}
								.frame(maxWidth: .infinity, alignment: .leading)
								.conversationTileStyle(
									convo: convo,
									conversationId: conversationId,
									hoverId: hoverId
								)

								.onHover { hovering in
									hoverId = hovering ? convo.id : nil

									if hovering {
										NSCursor.pointingHand.push()
									} else {
										NSCursor.pop()
									}
								}
							}
							.buttonStyle(.plain)

							if convo.id != conversations.first?.id {
								Divider()
							}
						}
					}
				}
				.frame(maxWidth: .infinity)
			}
			.background(.backgroundBase)
			.frame(
				minWidth: 220,
				idealWidth: 250,
				maxHeight: .infinity,
				alignment: .leading
			)
		}

	}
}

#Preview {
	let conversation = Conversation(
		updatedAt: .now,
		title: "test conversation",
		messages: []
	)

	Sidebar(
		conversationId: .constant(conversation.id),
		streamingMessageID: .constant(conversation.messages.last?.id),
		isSidebarOpen: true,
		isSending: false,
		conversations: [conversation]
	)
}
