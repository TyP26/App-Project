//
//  SelectionTabBarController.swift
//  schoolApp1
//
//  Created by Matthias Park 2025 on 10/9/23.
//

import UIKit

final class SelectionTabBarController: UITabBarController {
    private var loginObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureInvite()
        
        loginObserver = NotificationCenter.default.addObserver(forName: .didLogInNotification, object: nil, queue: .main, using: { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.configureInvite()
        })
    }
    
    func configureInvite() {
        if let isDean = UserDefaults.standard.value(forKey: "is_dean") as? Bool {
            if isDean && viewControllers?.count ?? 0 < 4 {
                viewControllers?.insert(InviteViewController(), at: 2)
                viewControllers?[2].tabBarItem.title = "Invite"
                viewControllers?[2].tabBarItem.image = UIImage(systemName: "person.3.fill")
            }
            else if !isDean && viewControllers?.count ?? 0 == 4 {
                viewControllers?.remove(at: 2)
            }
            
        }
        else if viewControllers?.count ?? 0 == 4 {
            viewControllers?.remove(at: 2)
        }
    }
}
