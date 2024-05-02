//
//  AnnouncementsModels.swift
//  schoolApp1
//
//  Created by Matthias Park 2025 on 7/24/23.
//

import Foundation

struct Announcement
{
    let title: String
    let body: String
    let attachments: URL?
    let grade: Int
    let sentDate: String
    let senderEmail: String
    let senderName: String
    let announcementId: String
    let pinned: Bool
}

struct AnnouncementGrade
{
    let grade: Int
    var latestAnnouncement: LatestAnnouncement
}

struct LatestAnnouncement
{
    let sentDate: String
    let title: String
    let senderName: String
    let senderEmail: String
}
