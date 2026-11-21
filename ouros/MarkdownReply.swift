import Foundation
import SwiftUI

struct MarkdownReply: View {
	let source: String

	private enum ListMarker {
		case text(String)
		case task(checked: Bool)
	}

	private enum Content {
		case text(AttributedString, kind: PresentationIntent.Kind?)
		case table(MarkdownTable)
	}

	private struct Block {
		let content: Content
		let isQuoted: Bool
		let listDepth: Int
		let listMarker: ListMarker?
	}

	private var blocks: [Block] {
		guard let parsed = try? AttributedString(
			markdown: source,
			options: .init(interpretedSyntax: .full, appliesSourcePositionAttributes: true)
		) else { return [] }

		var blocks: [Block] = []
		var listedItems: Set<Int> = []
		var runs = parsed.runs[\.presentationIntent].makeIterator()
		var next = runs.next()

		while let (intent, range) = next {
			next = runs.next()
			let components = intent?.components ?? []
			let lists = components.filter { $0.kind == .orderedList || $0.kind == .unorderedList }
			var text = AttributedString(parsed[range])
			var marker: ListMarker?
			for component in components {
				guard case .listItem(let ordinal) = component.kind else { continue }
				if listedItems.insert(component.identity).inserted {
					if components.first?.kind == .paragraph, let checked = taskState(in: text) {
						marker = .task(checked: checked)
						let afterMarker = text.characters.dropFirst(3).drop(while: \.isWhitespace)
						text = AttributedString(text[afterMarker.startIndex...])
					} else {
						marker = .text(lists.first?.kind == .orderedList ? "\(ordinal)." : "•")
					}
				}
				break
			}

			let content: Content
			if let cell = tableCell(in: components) {
				var table = MarkdownTable(columns: cell.columns)
				table.set(text, row: cell.row, column: cell.column)
				while let (cellIntent, cellRange) = next,
					let nextCell = tableCell(in: cellIntent?.components ?? []),
					nextCell.tableID == cell.tableID
				{
					table.set(AttributedString(parsed[cellRange]), row: nextCell.row, column: nextCell.column)
					next = runs.next()
				}
				content = .table(table)
			} else {
				content = .text(text, kind: components.first?.kind)
			}

			blocks.append(Block(
				content: content,
				isQuoted: components.contains { $0.kind == .blockQuote },
				listDepth: lists.count,
				listMarker: marker
			))
		}
		return blocks
	}

	private func taskState(in text: AttributedString) -> Bool? {
		let prefix = String(text.characters.prefix(3))
		let checked: Bool
		switch prefix {
		case "[x]", "[X]": checked = true
		case "[ ]": checked = false
		default: return nil
		}

		guard let firstRun = text.runs.first,
			firstRun.inlinePresentationIntent?.contains(.code) != true,
			firstRun.link == nil,
			let position = firstRun.markdownSourcePosition,
			let range = Range(position, in: source)
		else { return nil }

		let raw = source[range.lowerBound...]
		guard raw.hasPrefix(prefix),
			let separator = raw.dropFirst(3).first,
			separator == " " || separator == "\t" || separator.isNewline
		else { return nil }

		return checked
	}

	private struct TableCell {
		let tableID: Int
		let columns: [PresentationIntent.TableColumn]
		let row: Int
		let column: Int
	}

	private func tableCell(in components: [PresentationIntent.IntentType]) -> TableCell? {
		guard components.count >= 3,
			case .tableCell(let column) = components[0].kind,
			case .table(let columns) = components[2].kind
		else { return nil }

		let row: Int
		switch components[1].kind {
		case .tableHeaderRow: row = 0
		case .tableRow(let index): row = index
		default: return nil
		}

		return TableCell(tableID: components[2].identity, columns: columns, row: row, column: column)
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
				listMarker(block.listMarker)
					.frame(minWidth: 20, alignment: .trailing)
					.padding(.leading, CGFloat(block.listDepth - 1) * 18)
			}

			blockContent(block.content)
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
	private func listMarker(_ marker: ListMarker?) -> some View {
		switch marker {
		case .task(let checked):
			Image(systemName: checked ? "checkmark.square" : "square")
				.accessibilityLabel(checked ? Text("Completed task") : Text("Incomplete task"))
		case .text(let text):
			Text(verbatim: text)
				.monospacedDigit()
		case nil:
			Color.clear.frame(width: 0, height: 0)
		}
	}

	@ViewBuilder
	private func blockContent(_ content: Content) -> some View {
		switch content {
		case .table(let table):
			table
		case .text(let text, let kind):
			textBlock(text, kind: kind)
		}
	}

	@ViewBuilder
	private func textBlock(_ text: AttributedString, kind: PresentationIntent.Kind?) -> some View {
		switch kind {
		case .header(let level):
			heading(text, level: level)

		case .codeBlock:
			let code = String(text.characters)
			let displayCode = code.last == "\n" ? String(code.dropLast()) : code
			ScrollView(.horizontal) {
				Text(verbatim: displayCode)
					.font(.system(size: 13, design: .monospaced))
					.fixedSize(horizontal: true, vertical: false)
					.padding(8)
			}
			.background(.quaternary, in: RoundedRectangle(cornerRadius: 6))

		case .thematicBreak:
			rule

		default:
			Text(text)
		}
	}
	private func heading(_ text: AttributedString, level: Int) -> some View {
		let size: CGFloat = switch level {
		case 1: 24
		case 2: 20
		case 3: 17
		case 4: 15
		case 5: 14
		default: 13
		}

		return VStack(alignment: .leading, spacing: 6) {
			Text(text)
				.font(.system(size: size, weight: level == 1 ? .bold : .semibold))
				.opacity(level == 6 ? 0.75 : 1)
				.accessibilityAddTraits(.isHeader)

			if level == 1 {
				rule
			}
		}
		.padding(.top, level <= 2 ? 4 : 2)
	}

	private var rule: some View {
		Rectangle()
			.fill(.tertiary)
			.frame(height: 1)
			.accessibilityHidden(true)
	}
}

private struct MarkdownTable: View {
	let columns: [PresentationIntent.TableColumn]
	private var rows: [[Int: AttributedString]] = []

	init(columns: [PresentationIntent.TableColumn]) {
		self.columns = columns
	}

	mutating func set(_ text: AttributedString, row: Int, column: Int) {
		while rows.count <= row { rows.append([:]) }
		rows[row][column] = text
	}

	var body: some View {
		ScrollView(.horizontal) {
			Grid(horizontalSpacing: 0, verticalSpacing: 0) {
				ForEach(rows.indices, id: \.self) { row in
					if row > 0 {
						Divider()
							.gridCellUnsizedAxes(.horizontal)
					}

					GridRow(alignment: .firstTextBaseline) {
						ForEach(columns.indices, id: \.self) { column in
							Text(rows[row][column] ?? AttributedString(" "))
								.fontWeight(row == 0 ? .semibold : nil)
								.padding(.horizontal, 12)
								.padding(.vertical, 6)
								.gridColumnAlignment(alignment(of: columns[column]))
						}
					}
				}
			}
			.fixedSize(horizontal: true, vertical: false)
			.background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 6))
			.overlay {
				RoundedRectangle(cornerRadius: 6)
					.strokeBorder(.quaternary)
					.accessibilityHidden(true)
			}
		}
	}

	private func alignment(of column: PresentationIntent.TableColumn) -> HorizontalAlignment {
		switch column.alignment {
		case .center: .center
		case .right: .trailing
		default: .leading
		}
	}
}
