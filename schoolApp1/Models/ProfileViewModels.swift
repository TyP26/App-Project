//
//  ProfileViewModels.swift
//  schoolApp1
//
//  Created by Matthias Park 2025 on 6/27/23.
//

import Foundation

enum ProfileViewModelType
{
    case info, editableInfo, logout
}

struct ProfileViewModel {
    let viewModelType: ProfileViewModelType
    var title: String
    let identifier: String
    let handler: (() -> Void)?
}
