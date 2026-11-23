//
//  LocalModel.swift
//  ouros
//
//  Created by Mischa McLaughlin on 15/11/2026.
//

struct LocalModel: Decodable, Identifiable {
	let id: String
	var name: String { id }
	var alias: String

	init(id: String, alias: String? = nil) {
		self.id = id
		self.alias = alias ?? id
	}

	private enum CodingKeys: String, CodingKey {
		case id, alias
	}

	init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		let id = try values.decode(String.self, forKey: .id)
		let alias = try values.decodeIfPresent(String.self, forKey: .alias)
		self.init(id: id, alias: alias)
	}
}
