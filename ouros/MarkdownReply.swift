import Foundation
import SwiftUI

struct MarkdownReply: View {
	let source: String

	private struct Block {
		let text: AttributedString
		let kind: PresentationIntent.Kind?
		let isQuoted: Bool
		let listDepth: Int
		let listMarker: String?
	}

	private var blocks: [Block] {
		guard let parsed = try? AttributedString(
			markdown: source,
			options: .init(interpretedSyntax: .full)
		) else { return [] }

		var listedItems: Set<Int> = []
		return parsed.runs[\.presentationIntent].map { intent, range in
			let components = intent?.components ?? []
			let lists = components.filter { $0.kind == .orderedList || $0.kind == .unorderedList }
			var marker: String?
			for component in components {
				guard case .listItem(let ordinal) = component.kind else { continue }
				if listedItems.insert(component.identity).inserted {
					marker = lists.first?.kind == .orderedList ? "\(ordinal)." : "•"
				}
				break
			}

			return Block(
				text: AttributedString(parsed[range]),
				kind: components.first?.kind,
				isQuoted: components.contains { $0.kind == .blockQuote },
				listDepth: lists.count,
				listMarker: marker
			)
		}
	}

	var body: some View {
		let blocks = blocks
		VStack(alignment: .leading, spacing: 8) {
			if blocks.isEmpty {
				Text(verbatim: source)
			} else {
				ForEach(blocks.indices, id: \.self) { index in
					blockView(blocks[index])
				}
			}
		}
		.font(.system(size: 13))
	}

	private func blockView(_ block: Block) -> some View {
		HStack(alignment: .firstTextBaseline, spacing: 6) {
			if block.listDepth > 0 {
				Text(verbatim: block.listMarker ?? "")
					.monospacedDigit()
					.frame(minWidth: 20, alignment: .trailing)
					.padding(.leading, CGFloat(block.listDepth - 1) * 18)
			}

			blockContent(block)
		}
		.foregroundStyle(block.isQuoted ? Color.secondary : Color.primary)
		.padding(.leading, block.isQuoted ? 10 : 0)
		.overlay(alignment: .leading) {
			if block.isQuoted {
				Rectangle()
					.fill(.tertiary)
					.frame(width: 2)
					.accessibilityHidden(true)
			}
		}
	}

	@ViewBuilder
	private func blockContent(_ block: Block) -> some View {
		switch block.kind {
		case .header(let level):
			Text(block.text)
				.font(.system(size: max(14, 22 - CGFloat(level) * 2), weight: .semibold))
				.accessibilityAddTraits(.isHeader)

		case .codeBlock:
			let code = String(block.text.characters)
			let displayCode = code.last == "\n" ? String(code.dropLast()) : code
			ScrollView(.horizontal) {
				Text(verbatim: displayCode)
					.font(.system(size: 13, design: .monospaced))
					.fixedSize(horizontal: true, vertical: false)
					.padding(8)
			}
			.background(.quaternary, in: RoundedRectangle(cornerRadius: 6))

		default:
			Text(block.text)
		}
	}
}
