//
//  ConversationsModels.swift
//  schoolApp1
//
//  Created by Matthias Park 2025 on 6/27/23.
//

import Foundation

struct Conversation
{
    let id: String
    let conversationName: String
    let otherUserEmails: [String]
    let otherUserNames: [String]
    var latestMessage: LatestMessage
}

struct LatestMessage
{
    let date: String
    let text: String
    var isRead: Bool
}
