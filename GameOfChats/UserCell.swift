//
//  UserCell.swift
//  GameOfChats
//
//  Created by Bailig Abhanar on 2017-04-18.
//  Copyright © 2017 Bailig Abhanar. All rights reserved.
//

import UIKit
import Firebase

class UserCell: UITableViewCell {
    
    // will be set by MessagesController
    var message: Message? {
        didSet {
            setupNameAndProfileImage()
            detailTextLabel?.text = message?.text
            if let timestampString = message?.timestamp, let timestampDouble = Double(timestampString) {
                let timestampDate = Date(timeIntervalSince1970: timestampDouble)
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "hh:mm:ss a"
                timeLabel.text = dateFormatter.string(from: timestampDate)
            }
        }
    }
    
    private func setupNameAndProfileImage() {
        let chatPartnerId: String?
        
        if message?.fromUid == FIRAuth.auth()?.currentUser?.uid {
            chatPartnerId = message?.toUid
        } else {
            chatPartnerId = message?.fromUid
        }
        
        if let chatPartnerId = chatPartnerId {
            let ref = FIRDatabase.database().reference()
            let toUserRef = ref.child("users").child(chatPartnerId)
            toUserRef.observeSingleEvent(of: .value, with: { (snapshot) in
                guard let dictionary = snapshot.value as? [String: Any] else {
                    print("error: unable to fetch toUser!")
                    return
                }
                
                self.textLabel?.text = dictionary["name"] as? String
                
                if let profileImageUrl = dictionary["profileImageUrl"] as? String {
                    self.profileImageView.loadImageUsingCache(withUrlString: profileImageUrl)
                }
                
            }, withCancel: { (error) in
                print("error: \(error.localizedDescription)")
            })
        }
    }
    
    // will be set by NewMessageController
    var user: User? {
        didSet {
            textLabel?.text = user?.name
            detailTextLabel?.text = user?.email
            
            if let profileImageUrl = user?.profileImageUrl {
                // download the image
                profileImageView.loadImageUsingCache(withUrlString: profileImageUrl)
            }
        }
    }
    
    let timeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = UIColor.lightGray
        return label
    }()
    
    let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = CGFloat(48/2)
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        textLabel?.frame = CGRect(x: 70, y: textLabel!.frame.origin.y - 2, width: textLabel!.frame.width, height: textLabel!.frame.height)
        detailTextLabel?.frame = CGRect(x: 70, y: detailTextLabel!.frame.origin.y + 2, width: detailTextLabel!.frame.width, height: detailTextLabel!.frame.height)
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        addSubview(profileImageView)
        
        profileImageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 48).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 48).isActive = true
        
        
        addSubview(timeLabel)
        
        timeLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 18).isActive = true
        timeLabel.rightAnchor.constraint(equalTo: self.rightAnchor, constant: 8).isActive = true
        timeLabel.widthAnchor.constraint(equalToConstant: 100).isActive = true
        timeLabel.heightAnchor.constraint(equalTo: (self.textLabel?.heightAnchor)!).isActive = true
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
