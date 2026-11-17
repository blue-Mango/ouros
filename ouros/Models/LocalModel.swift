//
//  LocalModel.swift
//  ouros
//
//  Created by Mischa McLaughlin on 15/11/2026.
//

struct LocalModel: Decodable, Identifiable {
	let id: String
	var name: String { id }
}
