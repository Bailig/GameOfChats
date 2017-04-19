//
//  MessagesController.swift
//  GameOfChats
//
//  Created by Bailig Abhanar on 2017-04-16.
//  Copyright © 2017 Bailig Abhanar. All rights reserved.
//

import UIKit
import Firebase

class MessagesController: UITableViewController, LoginControllerDelegate, NewMessageControllerDelegate {

    var ref: FIRDatabaseReference?
    var messages = [Message]()
    var messagesDictionary = [String: Message]()
    let cellId = "cellId"
    
    // MARK: - view did load
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = FIRDatabase.database().reference()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(handleLogout))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(handleNewMessage))
        
        checkIfUserIsLogedIn()
        
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        
        observeMessage()
    }
    
    func observeMessage() {
        ref?.child("messages").observe(.childAdded, with: { (snapshot) in
            guard let dictionary = snapshot.value as? [String: Any] else {
                print("error: unable to fetch message!")
                return
            }
            let message = Message()
            message.setValuesForKeys(dictionary)
            if let toUid = message.toUid {
                self.messagesDictionary[toUid] = message
                self.messages = Array(self.messagesDictionary.values)
                self.messages.sort(by: { (m1, m2) -> Bool in
                    guard let t1 = m1.timestamp, let timestamp1 = Double(t1), let t2 = m2.timestamp, let timestamp2 = Double(t2) else {
                        return false
                    }
                    return timestamp1 > timestamp2
                })
            }
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }) { (error) in
            print("error: \(error.localizedDescription)")
        }
        
    }
    
    func checkIfUserIsLogedIn() {
        if let uid = FIRAuth.auth()?.currentUser?.uid {
            fetchUserAndSetNavBarTitle(withUid: uid)
        } else {
            // call handleLogout function after 0 second to present the login view
            perform(#selector(handleLogout), with: nil, afterDelay: 0)
            handleLogout()
        }
        
    }
    
    func fetchUserAndSetNavBarTitle(withUid uid: String) {
        ref?.child("users").child(uid).observeSingleEvent(of: .value, with: { (snapshot: FIRDataSnapshot) in
            guard let dictionary = snapshot.value as? [String: Any] else {
                print("error: unable to fetch user's name!")
                return
            }
            
            let user = User()
            user.setValuesForKeys(dictionary)
            self.setNavBar(withUser: user)
            
        }) { (error) in
            print("error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - setup UI

    func setNavBar(withUser user: User) {
        let titleView = UIView()
        titleView.frame = CGRect(x: 0, y: 0, width: 100, height: 40)
        
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        titleView.addSubview(containerView)
        
        let profileImageView = UIImageView()
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = 20
        profileImageView.clipsToBounds = true
        
        if let profileImageUrl = user.profileImageUrl {
            profileImageView.loadImageUsingCache(withUrlString: profileImageUrl)
        }
        
        containerView.addSubview(profileImageView)
        
        profileImageView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        let nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.text = user.name
        
        containerView.addSubview(nameLabel)
        
        nameLabel.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8).isActive = true
        nameLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        nameLabel.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        nameLabel.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        containerView.centerXAnchor.constraint(equalTo: titleView.centerXAnchor).isActive = true
        containerView.centerYAnchor.constraint(equalTo: titleView.centerYAnchor).isActive = true
        
        self.navigationItem.titleView = titleView
        
        titleView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleChatLog)))
    }
    
    
    // MARK: - handlers
    func handleNewMessage() {
        let newMessageController = NewMessageController()
        newMessageController.delegate = self
        let navController = UINavigationController(rootViewController: newMessageController)
        present(navController, animated: true, completion: nil)
    }
    
    func handleLogout() {
        
        do {
            try FIRAuth.auth()?.signOut()
        } catch let error {
            print("error: \(error.localizedDescription)")
        }
        
        // present loginController
        let loginController = LoginController()
        loginController.delegate = self
        present(loginController, animated: true, completion: nil)
    }
    
    func handleChatLog(forSelectedUser user: User) {
        let chatLogController = ChatLogController(collectionViewLayout: UICollectionViewFlowLayout())
        chatLogController.toUser = user
        navigationController?.pushViewController(chatLogController, animated: true)
    }
    
    // MARK: - setup table view
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as? UserCell else {
            print("error: unavle to dequeue reusable cell with identifier \(cellId)")
            return UITableViewCell()
        }
        
        cell.message = messages[indexPath.row]
        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    
}



