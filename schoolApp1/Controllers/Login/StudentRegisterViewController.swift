//
//  StudentRegisterViewController.swift
//  schoolApp1
//
//  Created by Yash Jagtap on 5/14/23.
//

import Firebase
import UIKit
import FirebaseAuth
import JGProgressHUD

final class StudentRegisterViewController: UIViewController {
    private let spinner = JGProgressHUD(style: .dark)
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "person.circle")
        imageView.tintColor = .gray
        imageView.contentMode = .scaleAspectFit
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.lightGray.cgColor
        return imageView
    }()
    
    private let firstNameField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "First Name. . ."
        field.leftView = UIView(frame:CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        return field
    }()
    private let lastNameField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Last Name. . ."
        field.leftView = UIView(frame:CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        return field
    }()
    private let gradeField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Grade. . ."
        field.leftView = UIView(frame:CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        return field
    }()
    private let emailField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Email Address. . ."
        field.leftView = UIView(frame:CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        return field
    }()
    
    private let passwordField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Password. . ."
        field.leftView = UIView(frame:CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        field.isSecureTextEntry = true
        return field
    }()
    
    private let registerButton: UIButton = {
        let button = UIButton()
        button.setTitle("Register", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    
    @objc private func didTapChangeProfilePic() {
        presentPhotoActionSheet()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        title = "Log In"
        view.backgroundColor = .systemBackground
        view.addSubview(imageView)
        
        registerButton.addTarget(self, action: #selector(registerButtonTapped), for: .touchUpInside)
        emailField.delegate = self
        passwordField.delegate = self
        
        //add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(firstNameField)
        scrollView.addSubview(lastNameField)
        scrollView.addSubview(gradeField)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(registerButton)
        
        imageView.isUserInteractionEnabled = true
        scrollView.isUserInteractionEnabled = true
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapChangeProfilePic))
        imageView.addGestureRecognizer(gesture)
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        let size = view.width/3
        imageView.frame = CGRect(x: (view.width - size)/2, y: 20 , width: size, height: size)
        firstNameField.frame = CGRect(x: 30, y: imageView.bottom + 10 , width: scrollView.width - 60, height: 52)
        imageView.layer.cornerRadius = imageView.width/2.0
        lastNameField.frame = CGRect(x: 30, y: firstNameField.bottom + 10 , width: scrollView.width - 60, height: 52)
        gradeField.frame = CGRect(x: 30, y: lastNameField.bottom + 10 , width: scrollView.width - 60, height: 52)
        emailField.frame = CGRect(x: 30, y: gradeField.bottom + 10 , width: scrollView.width - 60, height: 52)
        passwordField.frame = CGRect(x: 30, y: emailField.bottom + 10 , width: scrollView.width - 60, height: 52)
        registerButton.frame = CGRect(x: 30, y: passwordField.bottom + 10 , width: scrollView.width - 60, height: 52)
        
        
    }
    
    @objc private func registerButtonTapped() {
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        firstNameField.resignFirstResponder()
        lastNameField.resignFirstResponder()
        guard let firstName = firstNameField.text,
              let lastName = lastNameField.text,
              let grade = Int(gradeField.text ?? "0"),
              let email = emailField.text,
              let password = passwordField.text,
              !email.isEmpty,
              !password.isEmpty,
              !firstName.isEmpty,
              !lastName.isEmpty,
              password.count >= 6,
              grade >= 9,
              grade <= 12 else {
            var message = "Please enter all information to register"
            if (passwordField.text ?? "").count < 6 {
                message = "Passwords must contain at least 6 characters"
            }
            else if Int(gradeField.text ?? "0") ?? 0 < 9 || Int(gradeField.text ?? "0") ?? 0 > 12 {
                message = "Please enter a valid grade"
            }
            alertUserRegisterError(message: message)
            return
        }
        spinner.show(in: view)

        // Firebase Log In
        
        DatabaseManager.shared.userExists(with: email, completion: { [weak self] exists in
            guard let strongSelf = self else {
                return
            }
            
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()
            }

            guard !exists else {
                //user already exists
                strongSelf.alertUserRegisterError(message: "Looks like a user account for that email address already exists.")
                return
            }
            FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password, completion: {authResult, error  in
                guard authResult != nil, error == nil else {
                    print("Error creating user")
                    return
                }
                UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
                UserDefaults.standard.set(firstName, forKey: "first_name")
                UserDefaults.standard.set(lastName, forKey: "last_name")
                UserDefaults.standard.set(nil, forKey: "display_name")
                UserDefaults.standard.set(email, forKey: "email")
                UserDefaults.standard.set(false, forKey: "is_dean")
                UserDefaults.standard.set(grade, forKey: "grade")
                
                DatabaseManager.shared.provideSession(for: email, completion: nil)
                
                // Setting everyone that enters the app to all topic
                Messaging.messaging().subscribe(toTopic: "all") { error in
                  print("Subscribed to all topic")
                }
                
                NotificationCenter.default.post(name: .didLogInNotification, object: nil)
                
                let chatUser = ChatAppUser(firstName: firstName, lastName: lastName, displayName: nil, emailAddress: email, isDean: false, grade: grade)
                DatabaseManager.shared.insertUser(with: chatUser, completion: { success in
                    if success {
                        //upload image
                        guard let image = strongSelf.imageView.image, let data = image.pngData() else {
                            return
                        }
                        let fileName = chatUser.profilePictureFileName
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
                })
                
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
                
            })
        })
        
        
    }
    
    private func alertUserRegisterError(message: String) {
        let alert = UIAlertController(title: "Oops!", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
}

extension StudentRegisterViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            passwordField.becomeFirstResponder()
        }
        else if textField == passwordField {
            registerButtonTapped()
        }
        
        return true
    }
}

extension StudentRegisterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func presentPhotoActionSheet() {
        let actionSheet = UIAlertController(title: "Profile Picture", message: "How would you like to select a picture?", preferredStyle: .actionSheet)
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
    }
    func imagePickerControllerDidCancel( _ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}




