//
//  ChatLogController.swift
//  GameOfChats
//
//  Created by Bailig Abhanar on 2017-04-18.
//  Copyright © 2017 Bailig Abhanar. All rights reserved.
//

import UIKit
import Firebase

class ChatLogController: UICollectionViewController, UITextFieldDelegate, UICollectionViewDelegateFlowLayout {
    
    var ref: FIRDatabaseReference?
    var chatPartnerUser: User? {
        didSet {
            navigationItem.title = chatPartnerUser?.name
            observeMessagesForChatPartnerUser()
        }
    }
    
    var messagesWithChatPartner = [Message]()
    
    let cellId = "cellId"
    
    // MARK: - UI
    let inputsContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.white
        return view
    }()
    
    let sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Send", for: .normal)
        
        button.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        return button
    }()
    
    lazy var inputTextField: UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.placeholder = "Enter message..."
        tf.delegate = self
        return tf
    }()
    
    let separatorLineView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(r: 220, g: 220, b: 220)
        return view
    }()
    
    // MARK: - view did load
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = FIRDatabase.database().reference()
        
        collectionView?.backgroundColor = UIColor.white
        collectionView?.register(ChatMessageCell.self, forCellWithReuseIdentifier: cellId)
        collectionView?.alwaysBounceVertical = true
        
        view.addSubview(inputsContainerView)
        setupInputsContainerView()
        
        view.addSubview(separatorLineView)
        setupSeparatorLineView()
    }
    
    func observeMessagesForChatPartnerUser() {
        guard let currentUserUid = FIRAuth.auth()?.currentUser?.uid else {
            print("error: unable to fetch current user's uid!")
            return
        }
        
        ref = FIRDatabase.database().reference()
        let currentUserMessagesRef = ref?.child("user-messages").child(currentUserUid)
        currentUserMessagesRef?.observe(.childAdded, with: { (snapshot) in

            let messageId = snapshot.key
            let messagesRef = self.ref?.child("messages").child(messageId)
            messagesRef?.observeSingleEvent(of: .value, with: { (snapshot) in
                
                guard let dictionary = snapshot.value as? [String: Any] else { return }
                
                let message = Message()
                message.id = messageId
                message.setValuesForKeys(dictionary)
                if self.chatPartnerUser?.id == message.chatPartnerId() {
                    self.messagesWithChatPartner.append(message)
                    DispatchQueue.main.async {
                        self.collectionView?.reloadData()
                    }
                }
                
            }, withCancel: { (error) in
                print("error: \(error.localizedDescription)")
            })
            
        }) { (error) in
            print("error: \(error.localizedDescription)")
        }
    }
    
    
    // MARK: - setup UI
    func setupInputsContainerView() {
        inputsContainerView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        inputsContainerView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        inputsContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        inputsContainerView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        inputsContainerView.addSubview(sendButton)
        setupSendButton()
        
        inputsContainerView.addSubview(inputTextField)
        setupInputTextField()
        
    }
    
    func setupSendButton() {
        sendButton.topAnchor.constraint(equalTo: inputsContainerView.topAnchor).isActive = true
        sendButton.rightAnchor.constraint(equalTo: inputsContainerView.rightAnchor).isActive = true
        sendButton.bottomAnchor.constraint(equalTo: inputsContainerView.bottomAnchor).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
    }
    
    func setupInputTextField() {
        inputTextField.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor, constant: 16).isActive = true
        inputTextField.rightAnchor.constraint(equalTo: sendButton.leftAnchor, constant: 16).isActive = true
        inputTextField.topAnchor.constraint(equalTo: inputsContainerView.topAnchor).isActive = true
        inputTextField.bottomAnchor.constraint(equalTo: inputsContainerView.bottomAnchor).isActive = true
    }
    
    func setupSeparatorLineView(){
        separatorLineView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        separatorLineView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        separatorLineView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        separatorLineView.bottomAnchor.constraint(equalTo: inputsContainerView.topAnchor).isActive = true
    }
    
    
    // MARK: - handlers
    
    func handleSend() {
        guard let ref = ref, let text = inputTextField.text, !text.isEmpty else {
            print("error: unexpected nil for ref: FIRDatabaseReference")
            return
        }
        let fromUid = FIRAuth.auth()?.currentUser?.uid ?? ""
        let toUid = chatPartnerUser?.id ?? ""
        let messagesChildRef = ref.child("messages").childByAutoId()
        let timestamp = String(NSDate().timeIntervalSince1970)
        let values = ["text": text, "fromUid": fromUid, "toUid": toUid, "timestamp": timestamp]

        messagesChildRef.updateChildValues(values) { (error, ref) in
            if let error = error {
                print("error: \(error.localizedDescription)")
                return
            }
            let messageId = messagesChildRef.key
            
            let userMessagesRef = self.ref?.child("user-messages").child(fromUid)
            userMessagesRef?.updateChildValues([messageId: 1])
            
            let recipientUserMessageRef = self.ref?.child("user-messages").child(toUid)
            recipientUserMessageRef?.updateChildValues([messageId: 1])
            
        }
        
    }
    
    // MARK: - collection view
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as? ChatMessageCell else {
            print("error: unable to dequeqe reusable cell!")
            return UICollectionViewCell()
        }
        cell.textView.text = messagesWithChatPartner[indexPath.row].text
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messagesWithChatPartner.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: 80)
    }
    
    // MARK: - others
    // calls handleSend() method when enter key pressed
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        handleSend()
        return true
    }
}
