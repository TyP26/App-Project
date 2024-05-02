//
//  AnnouncementsViewController.swift
//  schoolApp1
//
//  Created by Matthias Park on 7/24/23.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

/// Controller that shows list of conversations
final class AnnouncementsViewController: UIViewController {
    //MARK: Repetition error with success messages too often
    private let spinner = JGProgressHUD(style: .dark)
    
    private var announcementGrades = [AnnouncementGrade]()
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.isHidden = true
        table.register(AnnouncementsTableViewCell.self, forCellReuseIdentifier: AnnouncementsTableViewCell.identifier)
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
    
    @objc private func didTapComposeButton() {
        let vc = NewAnnouncementViewController()
        vc.completion = { [weak self] result in
            self?.createNewAnnouncements(newAnnouncements: result)
        }
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC, animated: true)
    }
    
    func createNewAnnouncements(newAnnouncements: [Announcement]) {
        guard !newAnnouncements.isEmpty else {return}
        var nextNewAnnouncements = newAnnouncements
        nextNewAnnouncements.removeFirst()
        let currentAnnouncementGrades = announcementGrades
        let newAnnouncement = newAnnouncements.first!
        let targetGrade = newAnnouncement.grade
        if let targetAnnouncementGrade = currentAnnouncementGrades.first(where: {
            $0.grade == targetGrade
        }) {
            DatabaseManager.shared.createNewAnnouncement(with: newAnnouncement, completion: { [weak self] success in
                guard success else {
                    print("Failed to create new announcement")
                    return
                }
                if !nextNewAnnouncements.isEmpty {
                    self?.createNewAnnouncements(newAnnouncements: nextNewAnnouncements)
                }
            })
            if newAnnouncements.count == 1 {
                let vc = AnnouncementGradeViewController(with: targetAnnouncementGrade.grade)
                vc.title = "Grade \(targetAnnouncementGrade.grade) Announcements"
                vc.navigationItem.largeTitleDisplayMode = .never
                navigationController?.pushViewController(vc, animated: true)
            }
        }
        else {
            DatabaseManager.shared.createNewAnnouncementGrade(for: targetGrade, completion: { success in
                guard success else {
                    print("Failed to create new announcement grade")
                    return
                }
                DatabaseManager.shared.createNewAnnouncement(with: newAnnouncement, completion: { [weak self] success in
                    guard success else {
                        print("Failed to create new announcement")
                        return
                    }
                    if !nextNewAnnouncements.isEmpty {
                        self?.createNewAnnouncements(newAnnouncements: nextNewAnnouncements)
                    }
                })
            })
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        view.addSubview(noAnnouncementsLabel)
        setUpTableView()
        if UserDefaults.standard.value(forKey: "is_dean") as? Bool ?? false {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(didTapComposeButton))
        }
        else {
            navigationItem.rightBarButtonItem = nil
        }
        
        loginObserver = NotificationCenter.default.addObserver(forName: .didLogInNotification, object: nil, queue: .main, using: { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
            if UserDefaults.standard.value(forKey: "is_dean") as? Bool ?? false {
                strongSelf.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(strongSelf.didTapComposeButton))
            }
            else {
                strongSelf.navigationItem.rightBarButtonItem = nil
            }
            strongSelf.startListeningForAnnouncementsGrades()
        })
    }
    
    private func startListeningForAnnouncementsGrades() {
        print("Starting announcement grades fetch...")
        DatabaseManager.shared.getAllAnnouncementGrades(completion: { [weak self] result in
            switch result {
            case .success(let announcementGrades):
                print("Successfully got announcement grade models")
                guard !announcementGrades.isEmpty else {
                    self?.tableView.isHidden = true
                    self?.noAnnouncementsLabel.isHidden = false
                    return
                }
                self?.tableView.isHidden = false
                self?.noAnnouncementsLabel.isHidden = true
                self?.announcementGrades = announcementGrades
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            case .failure(let error):
                self?.tableView.isHidden = true
                self?.noAnnouncementsLabel.isHidden = false
                print("Failed to get announcement grades: \(error)")
            }
        })
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        validateAuth()
    }
    private func validateAuth() {
        if let currentUser = FirebaseAuth.Auth.auth().currentUser, let userEmail = currentUser.email {
            DatabaseManager.shared.provideSession(for: userEmail, completion: { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.startListeningForAnnouncementsGrades()
            })
        }
        else {
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
    }
}

extension AnnouncementsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return announcementGrades.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = announcementGrades[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: AnnouncementsTableViewCell.identifier, for: indexPath) as! AnnouncementsTableViewCell
        cell.configure(with: model)
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = announcementGrades[indexPath.row]
        openAnnouncementGrades(model)
    }
    
    func openAnnouncementGrades(_ model: AnnouncementGrade) {
        let vc = AnnouncementGradeViewController(with: model.grade)
        vc.title =  "Grade \(model.grade) Announcements"
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
}
