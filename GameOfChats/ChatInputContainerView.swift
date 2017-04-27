//
//  ChatInputContainerView.swift
//  GameOfChats
//
//  Created by Bailig Abhanar on 2017-04-27.
//  Copyright © 2017 Bailig Abhanar. All rights reserved.
//

import UIKit

protocol ChatInputContainerViewDelegate {
    func handleUpload()
    func handleSend()
}

class ChatInputContainerView: UIView, UITextFieldDelegate {
    
    var delegate: ChatInputContainerViewDelegate? {
        didSet {
            sendButton.addTarget(delegate, action: #selector(ChatLogController.handleSend), for: .touchUpInside)
            uploadImageView.addGestureRecognizer(UITapGestureRecognizer(target: delegate, action: #selector(ChatLogController.handleUpload)))
        }
    }
    
    lazy var inputTextField: UITextField = {
        let inputTextField = UITextField()
        inputTextField.translatesAutoresizingMaskIntoConstraints = false
        inputTextField.placeholder = "Enter message..."
        inputTextField.delegate = self
        return inputTextField
    }()
    
    
    let uploadImageView: UIImageView = {
        let uploadImageView = UIImageView()
        uploadImageView.translatesAutoresizingMaskIntoConstraints = false
        uploadImageView.image = UIImage(named: "upload_image_icon")
        uploadImageView.isUserInteractionEnabled = true
        return uploadImageView
    }()
    
    let sendButton: UIButton = {
        let sendButton = UIButton(type: .system)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.setTitle("Send", for: .normal)
        return sendButton
    }()
    
    let separatorLineView: UIView = {
        let separatorLineView = UIView()
        separatorLineView.translatesAutoresizingMaskIntoConstraints = false
        separatorLineView.backgroundColor = UIColor(r: 220, g: 220, b: 220)
        return separatorLineView
    }()
    
    // calls handleSend() method when enter key pressed
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        delegate?.handleSend()
        return true
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.white
        
        addSubview(uploadImageView)
        uploadImageView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        uploadImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        uploadImageView.widthAnchor.constraint(equalToConstant: 44).isActive = true
        uploadImageView.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        addSubview(sendButton)
        sendButton.topAnchor.constraint(equalTo: topAnchor).isActive = true
        sendButton.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        sendButton.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        
        addSubview(self.inputTextField)
        self.inputTextField.leftAnchor.constraint(equalTo: uploadImageView.rightAnchor, constant: 8).isActive = true
        self.inputTextField.rightAnchor.constraint(equalTo: sendButton.leftAnchor, constant: 16).isActive = true
        self.inputTextField.topAnchor.constraint(equalTo: topAnchor).isActive = true
        self.inputTextField.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        addSubview(separatorLineView)
        separatorLineView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        separatorLineView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        separatorLineView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        separatorLineView.bottomAnchor.constraint(equalTo: topAnchor).isActive = true
        

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
