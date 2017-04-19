//
//  NewMessageController.swift
//  GameOfChats
//
//  Created by Bailig Abhanar on 2017-04-17.
//  Copyright © 2017 Bailig Abhanar. All rights reserved.
//

import UIKit
import Firebase

protocol NewMessageControllerDelegate: class {
    func handleChatLog(forChatPartnerUser user: User)
}

class NewMessageController: UITableViewController {

    let cellId = "cellId"
    var ref: FIRDatabaseReference?
    var users = [User]()
    weak var delegate: NewMessageControllerDelegate?
    
    // MARK: - view did load
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = FIRDatabase.database().reference()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(handleCancel))
        
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        
        fetchAllUsers()
    }
    
    func fetchAllUsers() {
        ref?.child("users").observe(.childAdded, with: { (snapshot) in
            guard let dictionary = snapshot.value as? [String: Any] else {
                return
            }
            let user = User()
            user.id = snapshot.key
            user.setValuesForKeys(dictionary)
            self.users.append(user)
            
            //this will crash because of background thread, so lets use DispatchQueue to fix
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }, withCancel: { (error) in
            print("error: \(error.localizedDescription)")
        })
    }
    
    // MARK: - handlers
    func handleCancel() {
        dismiss(animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedUser = users[indexPath.row]
        dismiss(animated: true) {
            self.delegate?.handleChatLog(forChatPartnerUser: selectedUser)
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as? UserCell else {
            print("error: unable to dequeue reusable cell with identifier \(cellId)")
            return UITableViewCell()
        }
        cell.user = users[indexPath.row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
}
