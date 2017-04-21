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
    var chatPartner: User? {
        didSet {
            navigationItem.title = chatPartner?.name
            observeMessagesForChatPartnerUser()
        }
    }
    
    var messages = [Message]()
    let cellId = "cellId"
    
    
    // MARK: - view did load
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = FIRDatabase.database().reference()
        
        collectionView?.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
//        collectionView?.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        collectionView?.backgroundColor = UIColor.white
        collectionView?.register(ChatMessageCell.self, forCellWithReuseIdentifier: cellId)
        collectionView?.alwaysBounceVertical = true
        collectionView?.keyboardDismissMode = .interactive
        
    }
    
    func observeMessagesForChatPartnerUser() {
        guard let currentUserUid = FIRAuth.auth()?.currentUser?.uid, let chatPartnerUid = chatPartner?.id else {
            print("error: unable to fetch current user's uid!")
            return
        }
        
        ref = FIRDatabase.database().reference()
        let currentUserMessagesRef = ref?.child("user-messages").child(currentUserUid).child(chatPartnerUid)
        currentUserMessagesRef?.observe(.childAdded, with: { (snapshot) in

            let messageId = snapshot.key
            let messagesRef = self.ref?.child("messages").child(messageId)
            messagesRef?.observeSingleEvent(of: .value, with: { (snapshot) in
                
                guard let dictionary = snapshot.value as? [String: Any] else { return }
                
                let message = Message()
                message.id = messageId
                message.setValuesForKeys(dictionary)
                self.messages.append(message)
                DispatchQueue.main.async {
                    self.collectionView?.reloadData()
                }
                
            }, withCancel: { (error) in
                print("error: \(error.localizedDescription)")
            })
            
        }) { (error) in
            print("error: \(error.localizedDescription)")
        }
    }
    
    
    // MARK: - setup UI
    lazy var inputTextField: UITextField = {
        let inputTextField = UITextField()
        inputTextField.translatesAutoresizingMaskIntoConstraints = false
        inputTextField.placeholder = "Enter message..."
        inputTextField.delegate = self
        return inputTextField
    }()
    
    lazy var inputsContainerView: UIView = {
        let containerView = UIView()
        containerView.backgroundColor = UIColor.white
        containerView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50)
        
        
        let sendButton = UIButton(type: .system)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.setTitle("Send", for: .normal)
        sendButton.addTarget(self, action: #selector(self.handleSend), for: .touchUpInside)
        containerView.addSubview(sendButton)
        sendButton.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        sendButton.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        sendButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 80).isActive = true

        containerView.addSubview(self.inputTextField)
        self.inputTextField.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 16).isActive = true
        self.inputTextField.rightAnchor.constraint(equalTo: sendButton.leftAnchor, constant: 16).isActive = true
        self.inputTextField.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        self.inputTextField.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
        
        let separatorLineView = UIView()
        separatorLineView.translatesAutoresizingMaskIntoConstraints = false
        separatorLineView.backgroundColor = UIColor(r: 220, g: 220, b: 220)
        containerView.addSubview(separatorLineView)
        separatorLineView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        separatorLineView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        separatorLineView.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        separatorLineView.bottomAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        
        return containerView
    }()
    
    override var inputAccessoryView: UIView? {
        return inputsContainerView
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }

    
    // MARK: - handlers
    
    func handleSend() {
        guard let ref = ref, let text = inputTextField.text, !text.isEmpty else {
            print("error: unexpected nil for ref: FIRDatabaseReference")
            return
        }
        let fromUid = FIRAuth.auth()?.currentUser?.uid ?? ""
        let toUid = chatPartner?.id ?? ""
        let messagesChildRef = ref.child("messages").childByAutoId()
        let timestamp = String(NSDate().timeIntervalSince1970)
        let values = ["text": text, "fromUid": fromUid, "toUid": toUid, "timestamp": timestamp]

        messagesChildRef.updateChildValues(values) { (error, ref) in
            if let error = error {
                print("error: \(error.localizedDescription)")
                return
            }
            let messageId = messagesChildRef.key
            
            let userMessagesRef = self.ref?.child("user-messages").child(fromUid).child(toUid)
            userMessagesRef?.updateChildValues([messageId: 1])
            
            let recipientUserMessageRef = self.ref?.child("user-messages").child(toUid).child(fromUid)
            recipientUserMessageRef?.updateChildValues([messageId: 1])
        }
        inputTextField.text = nil
    }
    
    // MARK: - collection view
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as? ChatMessageCell, let text = messages[indexPath.item].text else {
            print("error: unable to dequeqe reusable cell!")
            return UICollectionViewCell()
        }
        
        cell.message = messages[indexPath.item]
        cell.chatPartner = chatPartner
        cell.bubbleViewWidthAnchor?.constant = estimatedFrame(forText: text).width + 32
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        guard let text = messages[indexPath.item].text else {
            print("error: unable to get messages' text!")
            return CGSize(width: view.frame.width, height: 80)
        }
        let height = estimatedFrame(forText: text).height + 20
        let width = UIScreen.main.bounds.width
        return CGSize(width: width, height: height)
    }
    
    private func estimatedFrame(forText text: String) -> CGRect {
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        let attributes = [NSFontAttributeName: UIFont.systemFont(ofSize: 16)]
        return NSString(string: text).boundingRect(with: size, options: options, attributes: attributes, context: nil)
    }
    
    // setup input UI to follow keyboard movement using NotificationCenter. input UI don't follow when dismiss keyboard interactively, so use inputAccessoryView.
    
//    override func viewDidDisappear(_ animated: Bool) {
//        super.viewDidDisappear(animated)
//        
//        // remove observers that sets inputs, text field and send button, to stay above keyboard.
//        // prevents memory leak
//        NotificationCenter.default.removeObserver(self)
//    }
//    
//    func setupKeyboardObservers() {
//        //        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardDidShow), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
//    }
//    func handleKeyboardWillShow(_ notification: Notification) {
//        let keyboardFrame = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as AnyObject).cgRectValue
//        let keyboardDuration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as AnyObject).doubleValue
//        
//        if let keyboardHeight = keyboardFrame?.height, let keyboardDuration = keyboardDuration {
//            inputsContainerViewBottomAnchor?.constant = -keyboardHeight
//            UIView.animate(withDuration: keyboardDuration) {
//                self.view.layoutIfNeeded()
//            }
//        }
//    }
//    func handleKeyboardWillHide(_ notification: Notification) {
//        let keyboardDuration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as AnyObject).doubleValue
//        
//        inputsContainerViewBottomAnchor?.constant = 0
//        
//        if let keyboardDuration = keyboardDuration {
//            UIView.animate(withDuration: keyboardDuration) {
//                self.view.layoutIfNeeded()
//            }
//        }
//        
//    }
    
    
    
    // MARK: - others
    // calls handleSend() method when enter key pressed
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        handleSend()
        return true
    }
    
    // this method will be call every time we rotate the device.
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView?.collectionViewLayout.invalidateLayout()
    }
}
