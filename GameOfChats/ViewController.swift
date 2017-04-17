//
//  ViewController.swift
//  GameOfChats
//
//  Created by Bailig Abhanar on 2017-04-16.
//  Copyright © 2017 Bailig Abhanar. All rights reserved.
//

import UIKit
import Firebase

class ViewController: UITableViewController {

    var ref: FIRDatabaseReference?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = FIRDatabase.database().reference()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(handleLogout))
        
        // user is not logged in
        if FIRAuth.auth()?.currentUser?.uid == nil {
            // call handleLogout function after 0
            perform(#selector(handleLogout), with: nil, afterDelay: 0)
            handleLogout()
        }
    }
    
    func handleLogout() {
        
        do {
            try FIRAuth.auth()?.signOut()
        } catch let error {
            print("error: \(error.localizedDescription)")
        }
        
        let loginController = LoginController()
        present(loginController, animated: true, completion: nil)
    }
}


