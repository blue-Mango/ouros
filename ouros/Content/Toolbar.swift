//
//  Toolbar.swift
//  ouros
//
//  Created by Mischa McLaughlin on 21/11/2026.
//

import SwiftUI

struct ToolBarItems: ToolbarContent {
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
					.fontInfoStyle()
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
							.fontInfoStyle()
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
				.fontInfoStyle()
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
						.fontInfoStyle()
				}
			} label: {
				HStack(spacing: 8) {
					Image(systemName: "cpu")
						.fontInfoStyle()
					Text(selectedModel ?? "Choose model")
						.fontInfoStyle()
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
					.fontInfoStyle()
			}
			.buttonStyle(.accessoryBarAction)
			.help("New chat")
			.disabled(isSending)
		}
		.sharedBackgroundVisibility(.hidden)
	}
}
