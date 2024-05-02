//
//  AnnouncementGradeTableViewCell.swift
//  schoolApp1
//
//  Created by Matthias Park 2025 on 7/28/23.
//

import UIKit
import SDWebImage

class AnnouncementGradeTableViewCell: UITableViewCell {

    static let identifier = "AnnouncementGradeTableViewCell"
    
    private var announcementId: String = ""
    private var grade: Int = 0
    private var isPinned: Bool = false
    
    private let pinnedButton: UIButton = {
        let button = UIButton()
        button.tintColor = .link
        return button
    }()

    private let announcementTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 21, weight: .semibold)
        label.numberOfLines = 0
        label.textColor = .white
        label.backgroundColor = .clear
        return label
    }()

    private let announcementBodyLabel: UITextView = {
        let textView = UITextView()
        textView.font = .systemFont(ofSize: 19, weight: .regular)
        textView.textColor = .white
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.isUserInteractionEnabled = false
        return textView
    }()
    
    private let senderNameLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.numberOfLines = 0
        label.textColor = .white
        label.backgroundColor = .clear
        return label
    }()
    
    private let senderImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 10
        imageView.layer.masksToBounds = true
        imageView.backgroundColor = .clear
        return imageView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        layer.borderWidth = 10
        layer.cornerRadius = 12
        
//        contentView.addSubview(userImageView)
        contentView.addSubview(pinnedButton)
        contentView.addSubview(announcementTitleLabel)
        contentView.addSubview(announcementBodyLabel)
        contentView.addSubview(senderNameLabel)
        contentView.addSubview(senderImageView)
        
        pinnedButton.addTarget(self, action: #selector(changePinned), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        pinnedButton.frame = CGRect(x: contentView.width - 40, y: 25, width: 20, height: 20)
        announcementTitleLabel.frame = CGRect(x: 20, y: 10, width: contentView.width - pinnedButton.width - 80, height: 50)
        announcementBodyLabel.frame = CGRect(x: 20, y: announcementTitleLabel.bottom + 10, width: contentView.width - 40, height: (contentView.height - announcementTitleLabel.height - 20))
        senderImageView.frame = CGRect(x: contentView.width - 40, y: contentView.height - 40, width: 20, height: 20)
        senderNameLabel.frame = CGRect(x: contentView.width / 2, y: contentView.height - 40, width: contentView.width / 2 - senderImageView.width - 30, height: 20)
    }
    
    @objc func changePinned() {
        guard let isDean = UserDefaults.standard.value(forKey: "is_dean") as? Bool, isDean else {return}
        
        DatabaseManager.shared.changeAnnouncementPinned(to: !isPinned, announcementId: announcementId, grade: grade, completion: { success in
            guard success else {
                print("Failed to change announcement pinned status")
                return
            }
        })
    }
    public func configure(with model: Announcement, url: URL?) {
        guard let isDean = UserDefaults.standard.value(forKey: "is_dean") as? Bool else {return}
        
        announcementId = model.announcementId
        grade = model.grade
        isPinned = model.pinned
        
        announcementBodyLabel.text = model.body
        announcementTitleLabel.text = model.title
        senderNameLabel.text = model.senderName
        senderImageView.sd_setImage(with: url, completed: nil)
        
        if !isDean {
            pinnedButton.isUserInteractionEnabled = false
        }
        
        if isPinned {
            pinnedButton.setImage(UIImage(systemName: "pin.fill"), for: .normal)
            pinnedButton.isHidden = false
        }
        else {
            pinnedButton.setImage(UIImage(systemName: "pin.slash"), for: .normal)
            if !isDean {
                pinnedButton.isHidden = true
            }
        }
        
        let newBackgroundView = UIView()
        newBackgroundView.layer.cornerRadius = 12
        if model.grade == 9 {
            backgroundColor = #colorLiteral(red: 0.4549019608, green: 0.7764705882, blue: 0.6156862745, alpha: 1)
            newBackgroundView.backgroundColor = #colorLiteral(red: 0.6214271188, green: 0.8422674537, blue: 0.7278635502, alpha: 1)
            layer.borderColor = #colorLiteral(red: 0.6214271188, green: 0.8422674537, blue: 0.7278635502, alpha: 1)
        }
        else if model.grade == 10 {
            backgroundColor = #colorLiteral(red: 0.3215686275, green: 0.7176470588, blue: 0.5333333333, alpha: 1)
            newBackgroundView.backgroundColor = #colorLiteral(red: 0.5228997469, green: 0.8034389615, blue: 0.6720094085, alpha: 1)
            layer.borderColor = #colorLiteral(red: 0.5228997469, green: 0.8034389615, blue: 0.6720094085, alpha: 1)
        }
        else if model.grade == 11 {
            backgroundColor = #colorLiteral(red: 0.2509803922, green: 0.568627451, blue: 0.4235294118, alpha: 1)
            newBackgroundView.backgroundColor = #colorLiteral(red: 0.3443439603, green: 0.7100188732, blue: 0.544375658, alpha: 1)
            layer.borderColor = #colorLiteral(red: 0.3443439603, green: 0.7100188732, blue: 0.544375658, alpha: 1)
        }
        else if model.grade == 12 {
            backgroundColor = #colorLiteral(red: 0.1764705882, green: 0.4156862745, blue: 0.3098039216, alpha: 1)
            newBackgroundView.backgroundColor = #colorLiteral(red: 0.2578569055, green: 0.6116253734, blue: 0.4586572051, alpha: 1)
            layer.borderColor = #colorLiteral(red: 0.2578569055, green: 0.6116253734, blue: 0.4586572051, alpha: 1)
        }
        selectedBackgroundView = newBackgroundView
    }
}
