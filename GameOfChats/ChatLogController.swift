//
//  ChatLogController.swift
//  GameOfChats
//
//  Created by Bailig Abhanar on 2017-04-18.
//  Copyright © 2017 Bailig Abhanar. All rights reserved.
//

import UIKit
import Firebase

class ChatLogController: UICollectionViewController, UITextFieldDelegate {
    
    var ref: FIRDatabaseReference?
    var toUser: User? {
        didSet {
            navigationItem.title = toUser?.name
        }
    }
    
    // MARK: - UI
    let inputsContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
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
        
        view.addSubview(inputsContainerView)
        setupInputsContainerView()
        
        view.addSubview(separatorLineView)
        setupSeparatorLineView()
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
        let toUid = toUser?.id ?? ""
        let messagesChildRef = ref.child("messages").childByAutoId()
        let timestamp = String(NSDate().timeIntervalSince1970)
        let values = ["text": text, "fromUid": fromUid, "toUid": toUid, "timestamp": timestamp]
        messagesChildRef.updateChildValues(values)
    }
    
    // MARK: - others
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        handleSend()
        return true
    }
}
