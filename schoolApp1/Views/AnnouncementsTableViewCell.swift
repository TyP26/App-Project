//
//  AnnouncementsTableViewCell.swift
//  schoolApp1
//
//  Created by Matthias Park 2025 on 7/24/23.
//

import UIKit
import SDWebImage
//MARK: Add profile picture
class AnnouncementsTableViewCell: UITableViewCell {
    
    static let identifier = "AnnouncementsTableViewCell"
    
//    private let userImageView: UIImageView = {
//        let imageView = UIImageView()
//        imageView.contentMode = .scaleAspectFill
//        imageView.layer.cornerRadius = 50
//        imageView.layer.masksToBounds = true
//        return imageView
//    }()
    
    private let announcementsGradeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 21, weight: .semibold)
        label.textColor = .white
        return label
    }()
    
    private let latestAnnouncementLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 19, weight: .regular)
        label.textColor = .white
        label.numberOfLines = 0
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        layer.cornerRadius = 12
        
//        contentView.addSubview(userImageView)
        contentView.addSubview(announcementsGradeLabel)
        contentView.addSubview(latestAnnouncementLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
//        userImageView.frame = CGRect(x: 10, y: 10, width: 100, height: 100)
        announcementsGradeLabel.frame = CGRect(x: 20, y: 20, width: contentView.width - 40, height: 25)
        latestAnnouncementLabel.frame = CGRect(x: 20, y: announcementsGradeLabel.bottom - 25, width: contentView.width - 40, height: contentView.height - announcementsGradeLabel.height - 20)
    }
    
    public func configure(with model: AnnouncementGrade) {
        latestAnnouncementLabel.text = "\(model.latestAnnouncement.senderName): \(model.latestAnnouncement.title)"
        announcementsGradeLabel.text = "\(DatabaseManager.formatGrade(grade: model.grade)) Announcements"
        
        let newBackgroundView = UIView()
        newBackgroundView.layer.cornerRadius = 12
        if model.grade == 9 {
            backgroundColor = #colorLiteral(red: 0.4549019608, green: 0.7764705882, blue: 0.6156862745, alpha: 1)
            newBackgroundView.backgroundColor = #colorLiteral(red: 0.6214271188, green: 0.8422674537, blue: 0.7278635502, alpha: 1)
        }
        else if model.grade == 10 {
            backgroundColor = #colorLiteral(red: 0.3215686275, green: 0.7176470588, blue: 0.5333333333, alpha: 1)
            newBackgroundView.backgroundColor = #colorLiteral(red: 0.5228997469, green: 0.8034389615, blue: 0.6720094085, alpha: 1)
        }
        else if model.grade == 11 {
            backgroundColor = #colorLiteral(red: 0.2509803922, green: 0.568627451, blue: 0.4235294118, alpha: 1)
            newBackgroundView.backgroundColor = #colorLiteral(red: 0.3443439603, green: 0.7100188732, blue: 0.544375658, alpha: 1)
        }
        else if model.grade == 12 {
            backgroundColor = #colorLiteral(red: 0.1764705882, green: 0.4156862745, blue: 0.3098039216, alpha: 1)
            newBackgroundView.backgroundColor = #colorLiteral(red: 0.2578569055, green: 0.6116253734, blue: 0.4586572051, alpha: 1)
        }
        selectedBackgroundView = newBackgroundView
        
//        let path = "profile_pictures/\(model.otherUserEmails[0])_profile_picture.png"
//        StorageManager.shared.downloadURL(for: path, completion: { [weak self] result in
//            switch result {
//            case .success(let url):
//                DispatchQueue.main.async {
//                    self?.userImageView.sd_setImage(with: url, completed: nil)
//                }
//            case .failure(let error):
//                print("Failed to get image url: \(error)")
//            }
//        })
    }
}
