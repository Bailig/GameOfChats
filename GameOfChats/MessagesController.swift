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
    var currentUser: User?
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
        
        // for view the delete button
        tableView.allowsMultipleSelectionDuringEditing = true
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
    
    // this function is being called from LoginController as well
    func fetchUserAndSetNavBarTitle(withUid uid: String) {
        ref?.child("users").child(uid).observeSingleEvent(of: .value, with: { (snapshot: FIRDataSnapshot) in
            guard let dictionary = snapshot.value as? [String: Any] else {
                print("error: unable to fetch user's name!")
                return
            }
            
            self.currentUser = User()
            self.currentUser?.setValuesForKeys(dictionary)
            self.currentUser?.id = uid
            self.setNavBar()
            
            self.observeUserMessages()
            
        }) { (error) in
            print("error: \(error.localizedDescription)")
        }
    }

    func observeUserMessages() {
        guard let uid = currentUser?.id else {
            print("error: unexpected nil found when getting currentUser!")
            return
        }
        // clear messages before append
        self.messages.removeAll()
        self.messagesDictionary.removeAll()
        
        let userMessageRef = ref?.child("user-messages").child(uid)
        userMessageRef?.observe(.childAdded, with: { (snapshot) in
            
            let chatPartnerUid = snapshot.key
            let chatPartnerRef = userMessageRef?.child(chatPartnerUid)
            
            chatPartnerRef?.observe(.childAdded, with: { (snapshot) in
                
                let messageId = snapshot.key
                self.fetchMessage(withMessageId: messageId)
                
            }, withCancel: { (error) in
                print("error: \(error.localizedDescription)")
            })
            
        }, withCancel: { (error) in
            print("error: \(error.localizedDescription)")
        })
        
        userMessageRef?.observe(.childRemoved, with: { (snapshot) in
            
            self.messagesDictionary.removeValue(forKey: snapshot.key)
            self.attemptReloadOfTable()
            
        }, withCancel: { (error) in
            print("error: \(error.localizedDescription)")
        })
    }
    
    private func fetchMessage(withMessageId messageId: String) {
        let messageRef = self.ref?.child("messages").child(messageId)
        
        messageRef?.observe(.value, with: { (snapshot) in
            
            guard let dictionary = snapshot.value as? [String: Any] else {
                print("error: unable to fetch message!")
                return
            }
            let message = Message(dictionary: dictionary)
            message.id = snapshot.key
            
            if let chatPartnerId = message.chatPartnerId() {
                self.messagesDictionary[chatPartnerId] = message
            }
            
            // reduces the number of times to reload table data
            self.attemptReloadOfTable()
            
        }, withCancel: { (error) in
            print("error: \(error.localizedDescription)")
        })
    }
    
    private func attemptReloadOfTable() {
        self.timer?.invalidate()
        //                print("canceled the timer")
        self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.handleReloadTable), userInfo: nil, repeats: false)
        //                print("scheduled a table reload in 0.1 sec")

    }
    // the timer used to reduce the number of times to reload table data
    var timer: Timer?
    func handleReloadTable() {
        
        self.messages = Array(self.messagesDictionary.values)
        self.messages.sort(by: { (m1, m2) -> Bool in
            guard let t1 = m1.timestamp, let t2 = m2.timestamp else {
                return false
            }
            return t1 > t2
        })
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
//            print("table reloaded")
        }
    }
    
    // MARK: - setup UI

    func setNavBar() {
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
        
        if let profileImageUrl = self.currentUser?.profileImageUrl {
            profileImageView.loadImageUsingCache(withUrlString: profileImageUrl)
        }
        
        containerView.addSubview(profileImageView)
        
        profileImageView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        let nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.text = self.currentUser?.name
        
        containerView.addSubview(nameLabel)
        
        nameLabel.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8).isActive = true
        nameLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        nameLabel.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        nameLabel.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        containerView.centerXAnchor.constraint(equalTo: titleView.centerXAnchor).isActive = true
        containerView.centerYAnchor.constraint(equalTo: titleView.centerYAnchor).isActive = true
        
        self.navigationItem.titleView = titleView
        
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
    
    func handleChatLog(forChatPartnerUser user: User) {
        let chatLogController = ChatLogController(collectionViewLayout: UICollectionViewFlowLayout())
        chatLogController.chatPartner = user
        navigationController?.pushViewController(chatLogController, animated: true)
    }
    
    // MARK: - setup table view
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let message = messages[indexPath.row]
        guard let chatPartnerId = message.chatPartnerId() else { return }
        
        let chatPartnerRef = ref?.child("users").child(chatPartnerId)
        chatPartnerRef?.observeSingleEvent(of: .value, with: { (snapshot) in
            
            guard let dictionary = snapshot.value as? [String: Any] else { return }
            
            let chatPartnerUser = User()
            chatPartnerUser.id = chatPartnerId
            chatPartnerUser.setValuesForKeys(dictionary)
            self.handleChatLog(forChatPartnerUser: chatPartnerUser)
            
        }, withCancel: { (error) in
            print("error: \(error.localizedDescription)")
        })
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as? UserCell else {
            print("error: unable to dequeue reusable cell with identifier \(cellId)")
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
    
    // MARK: - delete button
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        guard let ref = ref, let uid = FIRAuth.auth()?.currentUser?.uid else {
            print("error: unable to fetch current user id!")
            return
        }
        guard let chatPartnerId = messages[indexPath.row].chatPartnerId() else {
            print("error: unable to get chat partner id!")
            return
        }
        ref.child("user-messages").child(uid).child(chatPartnerId).removeValue { (error, ref) in
            if let error = error {
                print("error: \(error.localizedDescription)")
                return
            }
            self.messagesDictionary.removeValue(forKey: chatPartnerId)
            self.attemptReloadOfTable()
        }
        
        
    }
    
}



