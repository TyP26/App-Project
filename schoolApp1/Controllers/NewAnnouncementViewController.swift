//
//  NewAnnouncementViewController.swift
//  schoolApp1
//
//  Created by Matthias Park 2025 on 7/24/23.
//

import UIKit
import JGProgressHUD

final class NewAnnouncementViewController: UIViewController {

    public var completion: (([Announcement]) -> (Void))?

    private let spinner = JGProgressHUD(style: .dark)
    
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    
    private let promptLabel: UILabel = {
        let label = UILabel()
        label.text = "New Announcement"
        label.textAlignment = .center
        label.textColor = .label
        label.font = .systemFont(ofSize: 21, weight: .medium)
        return label
    }()

    private let titleField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Announcement Title. . ."
        field.leftView = UIView(frame:CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        return field
    }()
    
    private let bodyField: UITextView = {
        let textView = UITextView()
        textView.autocapitalizationType = .none
        textView.autocorrectionType = .no
        textView.returnKeyType = .continue
        textView.layer.cornerRadius = 12
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.lightGray.cgColor
        textView.backgroundColor = .secondarySystemBackground
        textView.font = .systemFont(ofSize: 17, weight: .regular)
        return textView
    }()
    
    private let placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = "Body..."
        label.sizeToFit()
        label.textColor = .tertiaryLabel
        label.font = .systemFont(ofSize: 17, weight: .regular)
        return label
    }()
    
    private let gradesField: UIStackView = {
        let stackView = UIStackView()
        stackView.distribution = .fillEqually
        stackView.axis = .vertical
        stackView.layer.cornerRadius = 12
        stackView.layer.borderWidth = 1
        stackView.layer.borderColor = UIColor.lightGray.cgColor
        stackView.backgroundColor = .secondarySystemBackground
        return stackView
    }()
    
    private let attachmentsField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Attachments. . ."
        field.leftView = UIView(frame:CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        return field
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
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        bodyField.delegate = self
        
        placeholderLabel.frame.origin = CGPoint(x: 5, y: (bodyField.font?.pointSize)! / 2)
        placeholderLabel.isHidden = !bodyField.text.isEmpty
        
        view.addSubview(promptLabel)
        view.addSubview(titleField)
        view.addSubview(bodyField)
        bodyField.addSubview(placeholderLabel)
        view.addSubview(gradesField)
        view.addSubview(attachmentsField)
        view.addSubview(confirmButton)
        
        let underclassmenStackView = UIStackView()
        underclassmenStackView.distribution = .fillEqually
        underclassmenStackView.backgroundColor = .secondarySystemBackground
        let upperclassmenStackView = UIStackView()
        upperclassmenStackView.distribution = .fillEqually
        upperclassmenStackView.backgroundColor = .secondarySystemBackground
        
        let freshmanCheckBox = CheckBox(with: 9)
        freshmanCheckBox.isChecked = false
        freshmanCheckBox.setTitle("  Freshmen", for: .normal)
        freshmanCheckBox.setTitleColor(#colorLiteral(red: 0.4549019608, green: 0.7764705882, blue: 0.6156862745, alpha: 1), for: .normal)
        let sophomoreCheckBox = CheckBox(with: 10)
        sophomoreCheckBox.isChecked = false
        sophomoreCheckBox.setTitle("  Sophomores", for: .normal)
        sophomoreCheckBox.setTitleColor(#colorLiteral(red: 0.3215686275, green: 0.7176470588, blue: 0.5333333333, alpha: 1), for: .normal)
        let juniorCheckBox = CheckBox(with: 11)
        juniorCheckBox.isChecked = false
        juniorCheckBox.setTitle("  Juniors", for: .normal)
        juniorCheckBox.setTitleColor(#colorLiteral(red: 0.2509803922, green: 0.568627451, blue: 0.4235294118, alpha: 1), for: .normal)
        let seniorCheckBox = CheckBox(with: 12)
        seniorCheckBox.isChecked = false
        seniorCheckBox.setTitle("  Seniors", for: .normal)
        seniorCheckBox.setTitleColor(#colorLiteral(red: 0.1764705882, green: 0.4156862745, blue: 0.3098039216, alpha: 1), for: .normal)
        
        underclassmenStackView.addArrangedSubview(freshmanCheckBox)
        underclassmenStackView.addArrangedSubview(sophomoreCheckBox)
        upperclassmenStackView.addArrangedSubview(juniorCheckBox)
        upperclassmenStackView.addArrangedSubview(seniorCheckBox)
        
        gradesField.addArrangedSubview(underclassmenStackView)
        gradesField.addArrangedSubview(upperclassmenStackView)

        confirmButton.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(gesture)

        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(dismissSelf))
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        promptLabel.frame = CGRect(x: (view.width / 2) - (promptLabel.width / 2), y: view.width / 8, width: view.width - 60, height: 78)
        titleField.frame = CGRect(x: 30, y: promptLabel.bottom + 10 , width: view.width - 60, height: 52)
        bodyField.frame = CGRect(x: 30, y: titleField.bottom + 10 , width: view.width - 60, height: 208)
        gradesField.frame = CGRect(x: 30, y: bodyField.bottom + 10 , width: view.width - 60, height: 104)
        attachmentsField.frame = CGRect(x: 30, y: gradesField.bottom + 10 , width: view.width - 60, height: 52)
        confirmButton.frame = CGRect(x: 30, y: attachmentsField.bottom + 10 , width: view.width - 60, height: 52)
    }
    
    @objc private func dismissKeyboard() {
        titleField.resignFirstResponder()
        bodyField.resignFirstResponder()
        attachmentsField.resignFirstResponder()
    }

    @objc private func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func confirmButtonTapped() {
        // make announcement
        titleField.resignFirstResponder()
        bodyField.resignFirstResponder()
        gradesField.resignFirstResponder()
        attachmentsField.resignFirstResponder()
        var grades: [Int] = []
        for gradesView in gradesField.arrangedSubviews {
            guard let stackView = gradesView as? UIStackView else {return}
            for view in stackView.arrangedSubviews {
                guard let checkBox = view as? CheckBox else {return}
                if checkBox.isChecked {
                    grades.append(checkBox.grade)
                }
            }
        }
        
//        gradesField.arrangedSubviews.compactMap({
//            guard let stackView = $0 as? UIStackView else {return}
//            return stackView.arrangedSubviews.compactMap({
//                guard let checkBox = $0 as? CheckBox else {return}
//                if checkBox.isChecked {
//                    return checkBox.grade
//                }
//                return nil
//            })
//        }).flatMap({$0})
        guard let title = titleField.text,
              let body = bodyField.text,
              !title.isEmpty,
              !body.isEmpty,
              title.count <= 75,
              body.count <= 750,
              !grades.isEmpty else {
            var message = "Please enter all relevant information to create a new announcement."
            let title = titleField.text ?? ""
            let body = bodyField.text ?? ""
            
            if grades.isEmpty {
                message = "Please choose a grade."
            }
            else if title.count > 75 {
                message = "Your title contains too many characters. Please reduce your title to 75 characters or less."
            }
            else if body.count > 750 {
                message = "Your body contains too many characters. Please reduce your body to 750 characters or less."
            }

            alertUserAnnouncementError(message: message)
            return
        }
        var attachments = URL(string: attachmentsField.text ?? "")
        if attachments != nil && !UIApplication.shared.canOpenURL(attachments!) {
            print("Invalid URL")
            attachments = nil
        }
        spinner.show(in: view)
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String,
              var currentUserName = UserDefaults.standard.value(forKey: "name") as? String else {return}
        if let currentUserDisplayName = UserDefaults.standard.value(forKey: "display_name") as? String {
            currentUserName = currentUserDisplayName
        }
        let safeCurrentEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        
        var newAnnouncements: [Announcement] = []
        for grade in grades {
            newAnnouncements.append(Announcement(title: title, body: body, attachments: attachments, grade: grade, sentDate: Self.dateFormatter.string(from: Date()), senderEmail: safeCurrentEmail, senderName: currentUserName, announcementId: createAnnouncementId(sender: safeCurrentEmail, date: Self.dateFormatter.string(from: Date()), grade: grade), pinned: false))
        }

        dismiss(animated: true, completion: { [weak self] in
            self?.completion?(newAnnouncements)
        })
    }
    
    private func createAnnouncementId(sender: String, date: String, grade: Int) -> String {
        return "grade_\(grade)_announcement_\(sender)_\(date)"
    }
    
    private func alertUserAnnouncementError(message: String) {
        let alert = UIAlertController(title: "Oops!", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
}

extension NewAnnouncementViewController: UITextViewDelegate
{
    func textViewDidChange(_ textView: UITextView) {
            placeholderLabel.isHidden = !textView.text.isEmpty
        }
}
