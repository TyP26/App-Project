//
//  AnnouncementGradeViewController.swift
//  schoolApp1
//
//  Created by Matthias Park 2025 on 7/28/23.
//
//MARK: showing only 10 announcements b4 needing extra button 2 load
//MARK: Click on announcement for more info
import UIKit
import FirebaseAuth
import JGProgressHUD

final class AnnouncementGradeViewController: UIViewController {
    //MARK: Reload on login/register
    private let spinner = JGProgressHUD(style: .dark)
    
    private var announcements = [Announcement]()
    
    private var announcementsGrade: Int
    
    private var profilePictureUrls: [String: URL?] = [:]
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.isHidden = true
        table.register(AnnouncementGradeTableViewCell.self, forCellReuseIdentifier: AnnouncementGradeTableViewCell.identifier)
        table.isHidden = true
        return table
        
    }()
    
    private let noAnnouncementsLabel: UILabel = {
        let label = UILabel()
        label.text = "No Announcements!"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 21, weight: .medium)
        return label
    }()
    
    private var loginObserver: NSObjectProtocol?
    
    init(with grade: Int) {
        self.announcementsGrade = grade
        super.init(nibName: nil, bundle: nil)
        startListeningForAnnouncements()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        view.addSubview(noAnnouncementsLabel)
        setUpTableView()
        
        loginObserver = NotificationCenter.default.addObserver(forName: .didLogInNotification, object: nil, queue: .main, using: { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.startListeningForAnnouncements()
        })
    }
    
    private func startListeningForAnnouncements() {
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        print("Starting announcement fetch...")
        
        DatabaseManager.shared.getAllAnnouncements(for: announcementsGrade, completion: { [weak self] result in
            switch result {
            case .success(let announcements):
                print("Successfully got announcement models")
                guard !announcements.isEmpty else {
                    self?.tableView.isHidden = true
                    self?.noAnnouncementsLabel.isHidden = false
                    return
                }
                
                var sortedAnnouncements = announcements
                sortedAnnouncements.sort(by: {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MMM dd, yyyy h:mm:ss a Z"
                    
                    guard let announcementDate = formatter.date(from: $0.sentDate.replacingOccurrences(of: "at ", with: "").replacingOccurrences(of: "CDT", with: "-0500").replacingOccurrences(of: "CST", with: "-0600")), let nextAnnouncementDate = formatter.date(from: $1.sentDate.replacingOccurrences(of: "at ", with: "").replacingOccurrences(of: "CDT", with: "-0500").replacingOccurrences(of: "CST", with: "-0600")) else {
                        self?.tableView.isHidden = true
                        self?.noAnnouncementsLabel.isHidden = false
                        return false
                    }
                    
                    return announcementDate >= nextAnnouncementDate
                })
                
                let pinnedAnnouncements = sortedAnnouncements.filter({$0.pinned})
                
                sortedAnnouncements.removeAll(where: {$0.pinned})
                
                let orderedAnnouncements = pinnedAnnouncements + sortedAnnouncements
                
                self?.tableView.isHidden = false
                self?.noAnnouncementsLabel.isHidden = true
                self?.announcements = orderedAnnouncements
                
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
                
            case .failure(let error):
                self?.tableView.isHidden = true
                self?.noAnnouncementsLabel.isHidden = false
                print("Failed to get announcements for grade \(self?.announcementsGrade ?? 0): \(error)")
            }
        })
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        validateAuth()
    }
    private func validateAuth() {
        if FirebaseAuth.Auth.auth().currentUser == nil {
            let vc = LoginViewController()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: false)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        noAnnouncementsLabel.frame = CGRect(x: 10, y: (view.height - 100) / 2, width: view.width - 20, height: 100)
    }
    
    
    private func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 68
        tableView.rowHeight = UITableView.automaticDimension
    }
    
    private func downloadProfilePictureUrl(for email: String) {
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else {return}
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        let fileName = email + "_profile_picture.png"
        let path = "profile_pictures/" + fileName
        if email == safeEmail {
            if let url = UserDefaults.standard.value(forKey: "profile_picture_url") as? URL {
                profilePictureUrls.updateValue(url, forKey: safeEmail)
                tableView.reloadData()
            }
            else {
                StorageManager.shared.downloadURL(for: path, completion: {[weak self] result in
                    switch result {
                    case .success(let url):
                        UserDefaults.standard.set(url, forKey: "profile_picture_url")
                        self?.profilePictureUrls.updateValue(url, forKey: safeEmail)
                        self?.tableView.reloadData()
                    case .failure(let error):
                        print("Failed to get download url: \(error)")
                    }
                })
            }
        }
        else {
            StorageManager.shared.downloadURL(for: path, completion: {[weak self] result in
                switch result {
                case .success(let url):
                    self?.profilePictureUrls.updateValue(url, forKey: email)
                    self?.tableView.reloadData()
                case .failure(let error):
                    print("Failed to get download url: \(error)")
                }
            })
        }
    }
}

extension AnnouncementGradeViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return announcements.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = announcements[indexPath.row]
        var url: URL? = profilePictureUrls.first(where: {$0.key == model.senderEmail})?.value
        if url == nil {
            downloadProfilePictureUrl(for: model.senderEmail)
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: AnnouncementGradeTableViewCell.identifier, for: indexPath) as! AnnouncementGradeTableViewCell
        cell.configure(with: model, url: url)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
//        let model = announcementGrades[indexPath.row]
//        openAnnouncementGrades(model)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 300
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableView.automaticDimension;
    }
}

