//
//  NewConversationViewController.swift
//  schoolApp1
//
//  Created by Matthias Park 2025 on 5/28/23.
//

import UIKit
import JGProgressHUD

final class NewConversationViewController: UIViewController {
    public var completion: (([SearchResult]) -> (Void))?
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private var users = [[String: String?]]()
    private var results = [SearchResult]()
    private var hasFetched = false
    private var selectedUsers = [SearchResult]()
    
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search for Users…"
        return searchBar
    }()
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.isHidden = true
        table.allowsMultipleSelection = true
        table.register(NewConversationTableViewCell.self, forCellReuseIdentifier: NewConversationTableViewCell.identifier)
        return table
    }()
    
    private let noResultsLabel: UILabel = {
        let label = UILabel()
        label.isHidden = true
        label.text = "No Results"
        label.textAlignment = .center
        label.textColor = .link
        label.font = .systemFont(ofSize: 21, weight: .medium)
        return label
    }()
    
    private let selectedUsersLabel: UILabel = {
        let label = UILabel()
        label.text = "No Users Selected"
        label.textAlignment = .center
        label.textColor = .label
        label.font = .systemFont(ofSize: 21, weight: .medium)
        return label
    }()
    
    private let confirmButton: UIButton = {
        let button = UIButton()
        button.setTitle("Confirm", for: .normal)
        button.setTitle("Pressed", for: .application)
        button.titleLabel!.textAlignment = .center
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(.red, for: .application)
        button.titleLabel!.font = .systemFont(ofSize: 21, weight: .medium)
        button.layer.cornerRadius = 12
        button.backgroundColor = #colorLiteral(red: 0.227152288, green: 0.5381186008, blue: 0.3243650198, alpha: 1)
        button.isHidden = true
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(noResultsLabel)
        view.addSubview(tableView)
        view.addSubview(selectedUsersLabel)
        view.addSubview(confirmButton)
        
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        
        confirmButton.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)
        
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(dismissSelf))
        searchBar.becomeFirstResponder()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = CGRect(x: view.left, y: view.top + 135, width: view.width, height: view.height - 135)
        noResultsLabel.frame = CGRect(x: view.width / 4, y: (view.height - 200) / 2, width: view.width / 2, height: 200)
        selectedUsersLabel.frame = CGRect(x: view.left, y: 50, width: view.width, height: 90)
        confirmButton.frame = CGRect(x: view.width / 2 - confirmButton.width / 2, y: view.height - 90, width: view.width / 2, height: 45)
    }
    
    @objc private func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func confirmButtonTapped() {
        // start conversation
        let targetUsersData = selectedUsers
        
        dismiss(animated: true, completion: { [weak self] in
            self?.completion?(targetUsersData)
        })
    }
    
    func updateSelectedUsersLabel() {
        var selectedNames: [String] = []
        for user in selectedUsers {
            if user.displayName.isEmpty {
                selectedNames.append(user.name)
            }
            else {
                selectedNames.append(user.displayName)
            }
        }
        let usersString = DatabaseManager.formatNames(names: selectedNames)
        if usersString.isEmpty {
            selectedUsersLabel.text = "No Users Selected"
        }
        else {
            selectedUsersLabel.text = usersString
        }
    }
    
    func updateConfirmButton() {
        confirmButton.isHidden = selectedUsers.isEmpty
    }
}

extension NewConversationViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NewConversationTableViewCell.identifier, for: indexPath) as! NewConversationTableViewCell
        let model = results[indexPath.row]
        cell.configure(with: model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let model = results[indexPath.row]
        if selectedUsers.contains(where: {$0.email == model.email}) {
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Add user to list
        selectedUsers.append(results[indexPath.row])
        updateSelectedUsersLabel()
        updateConfirmButton()
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        // Remove user from list
        selectedUsers.removeAll(where: {$0.email == results[indexPath.row].email})
        updateSelectedUsersLabel()
        updateConfirmButton()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
    
}

extension NewConversationViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, !text.replacingOccurrences(of: " ", with: "").isEmpty else {return}
        
        searchBar.resignFirstResponder()
        results.removeAll()
        spinner.show(in: view)
        
        searchUsers(query: text)
    }
    //MARK: Add filters: by grade, last name, reversed alphabetical, etc.
    func searchUsers(query: String) {
        //check if array has firebase results
        if hasFetched {
            //if it does: filter
            filterUsers(with: query)
        }
        else {
            //if not, fetch then filter
            DatabaseManager.shared.getAllUsers(completion: { [weak self] result in
                switch result {
                case .success(let usersCollection):
                    self?.hasFetched = true
                    self?.users = usersCollection
                    self?.filterUsers(with: query)
                case .failure(let error):
                    print("Failed to get users: \(error)")
                }
            })
        }
    }
    
    func filterUsers(with term: String) {
        //update the UI: either show results or show no results label
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String, hasFetched else {return}
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        
        spinner.dismiss()
        
        let filteredResults: [SearchResult] = users.filter({
            guard let firstName = $0["first_name"] as? String else {
                return false
            }
            
            guard let lastName = $0["last_name"] as? String else {
                return false
            }
            
            guard let email = $0["email"] as? String, email != safeEmail else {
                return false
            }
            
            if let displayName = $0["display_name"] as? String, displayName.lowercased().hasPrefix(term.lowercased()) {
                return true
            }
            
            return firstName.lowercased().hasPrefix(term.lowercased()) || lastName.lowercased().hasPrefix(term.lowercased())
        }).compactMap({
            guard let firstName = $0["first_name"] as? String, let lastName = $0["last_name"] as? String, let displayName = $0["display_name"] ?? "", let email = $0["email"] as? String else {
                return nil
            }
            
            return SearchResult(firstName: firstName, lastName: lastName, displayName: displayName, email: email)
        })
        
        var sortedResults = filteredResults
        sortedResults.sort(by: {
            var name = $0.name
            var nextName = $1.name
            
            if !$0.displayName.isEmpty {
                name = $0.displayName
            }
            
            if !$1.displayName.isEmpty {
                nextName = $1.displayName
            }
            
            return name < nextName
        })
        
        self.results = sortedResults
        
        updateUI()
    }
    
    func updateUI() {
        let areResults = !results.isEmpty
        noResultsLabel.isHidden = areResults
        tableView.isHidden = !areResults
        
        if areResults {
            tableView.reloadData()
        }
    }
}
