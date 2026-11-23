//
//  Settings.swift
//  ouros
//
//  Created by Mischa McLaughlin on 22/11/2026.
//

import SwiftUI

struct Settings: View {
	@Binding var isLightMode: Bool
	@Binding var models: [LocalModel]

	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			Text("Settings")
				.fontTitleStyle()

			Divider()

			VStack(alignment: .leading, spacing: 4) {
				HStack(spacing: 16) {
					Text("Colour Scheme")
						.fontSubTitleStyle()
					Button {
						isLightMode.toggle()
					} label: {
						Image(systemName: isLightMode ? "sun.max" : "sun.max.fill")
							.foregroundStyle(.accent)
							.padding(8)
							.background {
								RoundedRectangle(cornerRadius: 8)
									.stroke(
										.separatorColour,
										lineWidth: 1
									)
									.fill(.backgroundCanvas)
							}
					}
					.buttonStyle(.plain)
					.contentShape(RoundedRectangle(cornerRadius: 8))
				}

				Divider()

				HStack(alignment: .top, spacing: 8) {
					Text("Models")
						.fontSubTitleStyle()

					Divider()

					ScrollView {
						VStack(alignment: .leading, spacing: 16) {
							ForEach($models) { $model in
								VStack(alignment: .leading, spacing: 4) {
									Divider()

									Text(model.name)
										.fontSubTitleStyle()

									HStack(spacing: 16) {
										Text("Alias")

										TextField("Model alias", text: $model.alias)
											.textFieldStyle(.roundedBorder)
											.frame(width: 200)
									}
								}
							}
						}
					}
				}
			}
			.fontInfoStyle()
		}
		.padding()
		.frame(minWidth: 300, minHeight: 200, alignment: .top)
		.background(.backgroundBase)
		.toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
	}
}
