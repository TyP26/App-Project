//
//  SearchResult.swift
//  schoolApp1
//
//  Created by Matthias Park 2025 on 6/27/23.
//

import Foundation

struct SearchResult {
    var name: String {
        "\(firstName) \(lastName)"
    }
    let firstName: String
    let lastName: String
    let displayName: String
    let email: String
}
