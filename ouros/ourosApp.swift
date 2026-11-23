//
//  ourosApp.swift
//  ouros
//
//  Created by Mischa McLaughlin on 15/11/2026.
//

import SwiftUI

@main
struct ourosApp: App {
	@State var isLightMode = true
	@State var models: [LocalModel] = []

	var body: some Scene {

		WindowGroup("Ouros") {
			ContentView(models: $models)
				.preferredColorScheme(
					isLightMode ? .light : .dark
				)
				.task {
					do {
						models = try await MLXClient().fetchModels()
					} catch {
						print("MLX error:", error)
					}
				}
		}

		SwiftUI.Settings {
			Settings(isLightMode: $isLightMode, models: $models)
				.preferredColorScheme(isLightMode ? .light : .dark)
		}
	}

	@MainActor
	private func getModels() async {
		do {
			models = try await MLXClient().fetchModels()
		} catch {
			print("MLX error:", error)
		}
	}

}

#Preview("Ouros") {
	@Previewable @State var models: [LocalModel] = fakeModels

	ContentView(models: $models)
}

#Preview("Settings") {
	@Previewable @State var isLightMode = false
	@Previewable @State var models: [LocalModel] = fakeModels

	Settings(isLightMode: $isLightMode, models: $models)
}
