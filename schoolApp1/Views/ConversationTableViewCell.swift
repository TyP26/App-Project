//
//  ConversationTableViewCell.swift
//  schoolApp1
//
//  Created by Matthias Park 2025 on 6/9/23.
//

import UIKit
import SDWebImage

class ConversationTableViewCell: UITableViewCell {
    
    static let identifier = "ConversationTableViewCell"
    
    private let userImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 50
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    private let conversationNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 21, weight: .semibold)
        return label
    }()
    
    private let userMessageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 19, weight: .regular)
        label.numberOfLines = 0
        return label
    }()
    
    private let isReadImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "circle.fill"))
        imageView.tintColor = .link
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 10
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(userImageView)
        contentView.addSubview(conversationNameLabel)
        contentView.addSubview(userMessageLabel)
        contentView.addSubview(isReadImageView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        userImageView.frame = CGRect(x: 10, y: 10, width: 100, height: 100)
        conversationNameLabel.frame = CGRect(x: userImageView.frame.width + 20, y: 10, width: contentView.width - 80 - userImageView.width, height: (contentView.height - 20) / 2)
        userMessageLabel.frame = CGRect(x: userImageView.frame.width + 20, y: conversationNameLabel.bottom + 10, width: contentView.width - 20 - userImageView.width, height: (contentView.height - 20) / 2)
        isReadImageView.frame = CGRect(x: conversationNameLabel.left + conversationNameLabel.width + 20 , y: 10 + conversationNameLabel.height / 2 - isReadImageView.height / 2, width: 20, height: 20)
    }
    //MARK: Change this to dean priority
    public func configure(with model: Conversation) {
        userMessageLabel.text = model.latestMessage.text
        conversationNameLabel.text = model.conversationName
        isReadImageView.isHidden = model.latestMessage.isRead
        
        let path = "profile_pictures/\(model.otherUserEmails[0])_profile_picture.png"
        StorageManager.shared.downloadURL(for: path, completion: { [weak self] result in
            switch result {
            case .success(let url):
                DispatchQueue.main.async {
                    self?.userImageView.sd_setImage(with: url, completed: nil)
                }
            case .failure(let error):
                print("Failed to get image url: \(error)")
            }
        })
    }
}
