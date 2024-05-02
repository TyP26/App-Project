//
//  LoginViewController.swift
//  schoolApp1
//
//  Created by Yash Jagtap on 5/14/23.
//

import Firebase
import UIKit
import FirebaseAuth
import JGProgressHUD

final class LoginViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "logo")
        imageView.contentMode = .scaleAspectFit
        return imageView}()
    
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
    
    private let loginButton: UIButton = {
        let button = UIButton()
        button.setTitle("Log In", for: .normal)
        button.backgroundColor = .link
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    private var loginObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //NotificationManager.shared.getPermission()
        
        loginObserver = NotificationCenter.default.addObserver(forName: .didLogInNotification, object: nil, queue: .main, using: { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        })
        
        title = "Log In"
        view.backgroundColor = .systemBackground
        view.addSubview(imageView)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register", style: .done, target: self, action: #selector(didTapRegister))
        
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        emailField.delegate = self
        passwordField.delegate = self
        
        //add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(loginButton)
        
    }
    
    deinit {
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        let size = scrollView.frame.width/3
        imageView.frame = CGRect(x: (view.width - size)/2, y: 20 , width: size, height: size)
        emailField.frame = CGRect(x: 30, y: imageView.bottom + 10 , width: scrollView.width - 60, height: 52)
        passwordField.frame = CGRect(x: 30, y: emailField.bottom + 10 , width: scrollView.width - 60, height: 52)
        loginButton.frame = CGRect(x: 30, y: passwordField.bottom + 10 , width: scrollView.width - 60, height: 52)
        
        
    }
    
    @objc private func loginButtonTapped() {
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        guard let email = emailField.text, let password = passwordField.text, !email.isEmpty, !password.isEmpty, password.count >= 6 else {
            alertUserLoginError()
            return
        }
       
        spinner.show(in: view)
        //Firebase Log In
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password, completion: {[weak self] authResult, error in
           
            guard let strongSelf = self else {return}
            
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()
            }

            guard let result = authResult, error == nil else {
                print("Failed to log in user with email: \(email)")
                let alert = UIAlertController(title: "Oops!", message: "The account does not exist. To begin, please register.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self!.present(alert, animated: true)
                return
            }
            let user = result.user
            
            let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
            DatabaseManager.shared.getDataFor(path: safeEmail, completion: { result in
                switch result {
                case .success(let data):
                    guard let userData = data as? [String: Any],
                        let firstName = userData["first_name"] as? String,
                        let lastName = userData["last_name"] as? String,
                        let displayName = userData["display_name"] as? String?,
                        let isDean = userData["is_dean"] as? Bool,
                        let grade = userData["grade"] as? Int? else {
                        return
                    }
                    UserDefaults.standard.set(email, forKey: "email")
                    UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
                    UserDefaults.standard.set(firstName, forKey: "first_name")
                    UserDefaults.standard.set(lastName, forKey: "last_name")
                    UserDefaults.standard.set(displayName, forKey: "display_name")
                    UserDefaults.standard.set(isDean, forKey: "is_dean")
                    UserDefaults.standard.set(grade, forKey: "grade")
                    
                    DatabaseManager.shared.provideSession(for: email, completion: nil)
                    
                    // Setting everyone that enters the app to all topic
                    Messaging.messaging().subscribe(toTopic: "all") { error in
                      print("Subscribed to all topic")
                    }
                    
                    NotificationCenter.default.post(name: .didLogInNotification, object: nil)
                case .failure(let error):
                    print("Failed to read data with error \(error)")
                }
            })
            
            print("Logged In User: \(user)")
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        })
    }
    
    func alertUserLoginError() {
        let alert = UIAlertController(title: "Oops!", message: "Please enter all information to log in.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    
    
    @objc private func didTapRegister() {
        let vc = StatusViewController()
        vc.title = "Create Account"
        navigationController?.pushViewController(vc, animated: true)
    }
}
extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            passwordField.becomeFirstResponder()
        }
        else if textField == passwordField {
            loginButtonTapped()
        }
        
        return true
    }
}



