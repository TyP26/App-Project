//
//  ChatAppUser.swift
//  schoolApp1
//
//  Created by Matthias Park 2025 on 7/17/23.
//

import Foundation

struct ChatAppUser
{
    let firstName: String
    let lastName: String
    let displayName: String?
    let emailAddress: String
    let isDean: Bool
    let grade: Int?
    
    var safeEmail: String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    var profilePictureFileName: String {
        return "\(safeEmail)_profile_picture.png"
    }
}
