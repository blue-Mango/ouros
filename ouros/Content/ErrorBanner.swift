//
//  ErrorBanner.swift
//  ouros
//
//  Created by Mischa McLaughlin on 21/11/2026.
//

import SwiftUI

struct ErrorBanner: View {
	@Binding var chatError: String?

	@State private var isHovering = false

	var body: some View {
		if let error = chatError {
			HStack(spacing: 4) {
				Button {
					chatError = nil
				} label: {
					Label("Close error", systemImage: "xmark.square")
						.errorIconStyle(isHovering: isHovering)
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
						.frame(maxWidth: .infinity, alignment: .leading)
						.errorMessageStyle(isHovering: isHovering)
				}
			}
			.frame(maxWidth: .infinity, alignment: .bottomLeading)
			.padding()
		}
	}
}
