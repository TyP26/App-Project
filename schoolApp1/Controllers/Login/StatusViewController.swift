//
//  StatusViewController.swift
//  schoolApp1
//
//  Created by Matthias Park 2025 on 7/14/23.
//

import UIKit

final class StatusViewController: UIViewController {
    private let promptLabel: UILabel = {
        let label = UILabel()
        label.text = "Who are you registering as?"
        label.textAlignment = .center
        label.textColor = .label
        label.font = .systemFont(ofSize: 21, weight: .medium)
        return label
    }()
    private let studentButton: UIButton = {
        let button = UIButton()
        button.setTitle("Student", for: .normal)
        button.backgroundColor = #colorLiteral(red: 0.227152288, green: 0.5381186008, blue: 0.3243650198, alpha: 1)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    private let deanButton: UIButton = {
        let button = UIButton()
        button.setTitle("Dean", for: .normal)
        button.backgroundColor = #colorLiteral(red: 0.227152288, green: 0.5381186008, blue: 0.3243650198, alpha: 1)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        studentButton.addTarget(self, action: #selector(didTapStudent), for: .touchUpInside)
        deanButton.addTarget(self, action: #selector(didTapDean), for: .touchUpInside)
        view.addSubview(promptLabel)
        view.addSubview(studentButton)
        view.addSubview(deanButton)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        promptLabel.frame = CGRect(x: 30, y: view.height / 4, width: view.width - 60, height: 52)
        studentButton.frame = CGRect(x: 30, y: promptLabel.bottom + 20, width: view.width - 60, height: 52)
        deanButton.frame = CGRect(x: 30, y: studentButton.bottom + 20, width: view.width - 60, height: 52)
    }
    
    @objc private func didTapStudent() {
        let vc = StudentRegisterViewController()
        vc.title = "Student"
        navigationController?.pushViewController(vc, animated: true)
    }
    //MARK: How do we verify that the person is really a dean?
    @objc private func didTapDean() {
        let vc = DeanRegisterViewController()
        vc.title = "Dean"
        navigationController?.pushViewController(vc, animated: true)
    }
}
