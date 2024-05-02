//
//  ProfileViewController.swift
//  schoolApp1
//
//  Created by Yash Jagtap on 5/14/23.
//

import UIKit
import FirebaseAuth
import SDWebImage

final class ProfileViewController: UIViewController {
    @IBOutlet var tableView: UITableView!
    var data = [ProfileViewModel]()
    
    private var loginObserver: NSObjectProtocol?
    //MARK: Reload on login/register
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .white
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 3
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 75
        return imageView
    }()
    
    @objc private func changeProfilePicture() {
        presentPhotoActionSheet()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: ProfileTableViewCell.identifier)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = createTableHeader()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        updateProfile()
        
        loginObserver = NotificationCenter.default.addObserver(forName: .didLogInNotification, object: nil, queue: .main, using: { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.updateProfile()
        })
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        imageView.frame = CGRect(x: (view.width - 150) / 2, y: 75, width: 150, height: 150)
    }
    
    func updateProfile() {
        data.removeAll()
        
        updateProfilePicture()
        
        var status = "Student"
        var showDisplayName = false
        var displayName: String? = nil
        
        if UserDefaults.standard.value(forKey: "is_dean") as? Bool ?? false {
            status = "Dean"
            showDisplayName = true
            displayName = UserDefaults.standard.value(forKey: "display_name") as? String
        }
        
        data.append(ProfileViewModel(viewModelType: .info, title: "Name: \(UserDefaults.standard.value(forKey: "name") as? String ?? "No Name")", identifier: "name", handler: nil))
        if showDisplayName {
            data.append(ProfileViewModel(viewModelType: .editableInfo, title: "Display Name: \(displayName ?? "No Display Name")", identifier: "display name", handler: { [weak self] in
                
                guard let strongSelf = self else {return}
                
                let alert = UIAlertController(title: "Change Display Name", message: "What would you like your display name to be?", preferredStyle: .alert)
                alert.addTextField { field in
                    field.placeholder = "Display Name..."
                    field.returnKeyType = .done
                }
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "Confirm", style: .default, handler: { _ in
                    guard let fields = alert.textFields, fields.count == 1 else {return}
                    let displayNameField = fields[0]
                    var displayName: String? = displayNameField.text
                    if (displayName ?? "").replacingOccurrences(of: " ", with: "").isEmpty {
                        displayName = nil
                    }
                    DatabaseManager.shared.changeDisplayName(to: displayName, completion: { [weak self] success in
                        guard success else {
                            let alert = UIAlertController(title: "Error", message: "Failed to change display name", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .default))
                            strongSelf.present(alert, animated: true)
                            return
                        }
                        UserDefaults.standard.set(displayName, forKey: "display_name")
                        guard let profileData = self?.data else {return}
                        var newData: [ProfileViewModel] = []
                        for datum in profileData {
                            var newDatum = datum
                            if datum.identifier == "display name" {
                                newDatum.title = "Display Name: \(displayName ?? "No Display Name")"
                            }
                            newData.append(newDatum)
                        }
                        self?.data = newData
                        self?.tableView.reloadData()
                    })
                }))
                strongSelf.present(alert, animated: true)
            }))
        }
        data.append(ProfileViewModel(viewModelType: .info, title: "Email: \(UserDefaults.standard.value(forKey: "email") as? String ?? "No Email")", identifier: "email", handler: nil))
        if let grade = UserDefaults.standard.value(forKey: "grade") {
            data.append(ProfileViewModel(viewModelType: .info, title: "Grade: \(grade)", identifier: "grade", handler: nil))
        }
        data.append(ProfileViewModel(viewModelType: .info, title: "Account Status: \(status)", identifier: "account status", handler: nil))
        data.append(ProfileViewModel(viewModelType: .logout, title: "Log Out", identifier: "log out", handler: {[weak self] in
            guard let strongSelf = self else {return}
            
            let actionSheet = UIAlertController(title: "What would you like to do?", message: "", preferredStyle: .actionSheet)
            actionSheet.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { [weak self] _ in
                guard let strongSelf = self else {return}
                do {
                    try FirebaseAuth.Auth.auth().signOut()
                    DatabaseManager.shared.endSession(completion: {
                        UserDefaults.standard.set(nil, forKey: "name")
                        UserDefaults.standard.set(nil, forKey: "first_name")
                        UserDefaults.standard.set(nil, forKey: "last_name")
                        UserDefaults.standard.set(nil, forKey: "display_name")
                        UserDefaults.standard.set(nil, forKey: "email")
                        UserDefaults.standard.set(nil, forKey: "is_dean")
                        UserDefaults.standard.set(nil, forKey: "grade")
                        UserDefaults.standard.set(nil, forKey: "profile_picture_url")
                        
                        strongSelf.clearProfile()
                        
                        let vc = LoginViewController()
                        let nav = UINavigationController(rootViewController: vc)
                        nav.modalPresentationStyle = .fullScreen
                        strongSelf.present(nav, animated: true)
                    })
                }
                catch {
                    let alert = UIAlertController(title: "Error", message: "Failed to log out. Please try again.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self?.present(alert, animated: true)
                }
            }))
            actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            actionSheet.popoverPresentationController?.sourceView = strongSelf.view
            actionSheet.popoverPresentationController?.sourceRect = CGRect(x: 0, y: strongSelf.view.height - 100, width: strongSelf.view.width, height: 10)
            strongSelf.present(actionSheet, animated: true)

        }))
        
        tableView.reloadData()
    }
    
    func clearProfile() {
        data.removeAll()
        imageView.image = UIImage(systemName: "person.and.background.dotted")
        tableView.reloadData()
    }
    
    func createTableHeader() -> UIView? {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.width, height: 300))
        headerView.backgroundColor = #colorLiteral(red: 0.227152288, green: 0.5381186008, blue: 0.3243650198, alpha: 1)
        
        headerView.addSubview(imageView)
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(changeProfilePicture))
        headerView.addGestureRecognizer(gesture)
        
        return headerView
    }
    
    func updateProfilePicture() {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        imageView.image = UIImage(systemName: "person.and.background.dotted")
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        let fileName = safeEmail + "_profile_picture.png"
        let path = "profile_pictures/" + fileName
        
        if let url = UserDefaults.standard.value(forKey: "profile_picture_url") as? URL {
            imageView.sd_setImage(with: url, completed: nil)
        }
        else {
            StorageManager.shared.downloadURL(for: path, completion: {[weak self] result in
                switch result {
                case .success(let url):
                    UserDefaults.standard.set(url, forKey: "profile_picture_url")
                    self?.imageView.sd_setImage(with: url, completed: nil)
                case .failure(let error):
                    print("Failed to get download url: \(error)")
                }
            })
        }
    }
}
extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewModel = data[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ProfileTableViewCell.identifier, for: indexPath) as! ProfileTableViewCell
        cell.setUp(with: viewModel)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        data[indexPath.row].handler?()
        tableView.reloadData()
    }
}

extension ProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func presentPhotoActionSheet() {
        let actionSheet = UIAlertController(title: "Change Profile Picture", message: "How would you like to select a picture?", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        actionSheet.addAction(UIAlertAction(title: "Take Photo" , style: .default, handler: { [weak self] _ in
            self?.presentCamera()
        }))
        actionSheet.addAction(UIAlertAction(title: "Choose Photo" , style: .default, handler: { [weak self] _ in
            self?.presentPhotoPicker()
        }))
        actionSheet.popoverPresentationController?.sourceView = view
        actionSheet.popoverPresentationController?.sourceRect = CGRect(x: imageView.left, y: imageView.bottom + 125, width: imageView.width, height: 10)
        
        present(actionSheet, animated: true)
    }
    
    func presentCamera() {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func presentPhotoPicker() {
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]){
        picker.dismiss(animated: true, completion: nil)
        print(info)
        guard let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else {return}
        
        imageView.image = selectedImage
        //upload image
        guard let data = selectedImage.pngData(), let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        let fileName = "\(safeEmail)_profile_picture.png"
        StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName, completion: { result in
            switch result {
            case .success(let downloadUrl):
                UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                print(downloadUrl)
            case .failure(let error):
                print("Storage manager error: \(error)")
            }
        })
    }
    func imagePickerControllerDidCancel( _ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

class ProfileTableViewCell: UITableViewCell {
    static let identifier = "ProfileTableViewCell"
    
    public func setUp(with viewModel: ProfileViewModel) {
        textLabel?.text = viewModel.title
        switch viewModel.viewModelType {
        case .info:
            textLabel?.textAlignment = .left
            selectionStyle = .none
        case .editableInfo:
            textLabel?.textAlignment = .left
            selectionStyle = .none
        case .logout:
            textLabel?.textColor = .red
            textLabel?.textAlignment = .center
        }
    }
}
