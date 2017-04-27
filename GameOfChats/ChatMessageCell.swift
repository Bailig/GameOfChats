//
//  ChatMessageCell.swift
//  GameOfChats
//
//  Created by Bailig Abhanar on 2017-04-19.
//  Copyright © 2017 Bailig Abhanar. All rights reserved.
//

import UIKit
import Firebase
import AVFoundation

protocol ChatMessageCellDelegate {
    func preformZoomIn(forStartingImageView imageView: UIImageView)
}

class ChatMessageCell: UICollectionViewCell {
    
    static let blueColor = UIColor(r: 0, g: 137, b: 249)
    static let grayColor = UIColor(r: 240, g: 240, b: 240)
    
    
    var delegate: ChatMessageCellDelegate?
    
    var message: Message? {
        didSet {
            textView.text = message?.text
            if message?.fromUid == FIRAuth.auth()?.currentUser?.uid {
                // blue bubble
                bubbleView.backgroundColor = ChatMessageCell.blueColor
                textView.textColor = UIColor.white
                profileImageView.isHidden = true
                bubbleViewRightAnchor?.isActive = true
                bubbleViewLeftAnchor?.isActive = false
            } else {
                // gray bubble
                bubbleView.backgroundColor = ChatMessageCell.grayColor
                textView.textColor = UIColor.black
                bubbleViewRightAnchor?.isActive = false
                bubbleViewLeftAnchor?.isActive = true
                profileImageView.isHidden = false
            }
            if let messageImageUrl = message?.imageUrl {
                messageImageView.loadImageUsingCache(withUrlString: messageImageUrl)
                messageImageView.isHidden = false
                bubbleView.backgroundColor = UIColor.clear
            } else {
                messageImageView.isHidden = true
            }
        }
    }
    
    var chatPartner: User? {
        didSet {
            if let profileImageUrl = chatPartner?.profileImageUrl {
                profileImageView.loadImageUsingCache(withUrlString: profileImageUrl)
            }
        }
    }
    
    let profileImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.layer.cornerRadius = 16
        iv.layer.masksToBounds = true
        iv.contentMode = .scaleAspectFill
        return iv
    }()
    
    let textView: UITextView = {
        let tv = UITextView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.font = UIFont.systemFont(ofSize: 16)
        tv.backgroundColor = UIColor.clear
        tv.isEditable = false
        return tv
    }()
    
    let bubbleView: UIView = {
        let bv = UIView()
        bv.translatesAutoresizingMaskIntoConstraints = false
        bv.layer.cornerRadius = 16
        bv.layer.masksToBounds = true
        return bv
    }()
    
    lazy var messageImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.layer.cornerRadius = 16
        iv.layer.masksToBounds = true
        iv.contentMode = .scaleAspectFill
        iv.isUserInteractionEnabled = true
        iv.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleImageTap)))
        return iv
    }()
    
    let activityIndicatorView: UIActivityIndicatorView = {
        let aiv = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.white)
        aiv.translatesAutoresizingMaskIntoConstraints = false
        return aiv
    }()

    lazy var playButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = UIColor.white
        button.setImage(UIImage(named: "play"), for: .normal)
        button.isHidden = true
        
        button.addTarget(self, action: #selector(handlePlay), for: .touchUpInside)
        return button
    }()
    
    var playerLayer: AVPlayerLayer?
    var player: AVPlayer?
    
    func handlePlay() {
        if let videoUrlString = message?.videoUrl, let url = URL(string: videoUrlString) {
            player = AVPlayer(url: url)
            playerLayer = AVPlayerLayer(player: player)
            playerLayer?.frame = bubbleView.bounds
            if let playerLayer = playerLayer {
                bubbleView.layer.addSublayer(playerLayer)
                player?.play()
                activityIndicatorView.startAnimating()
                playButton.isHidden = true
            }
        }
    }
    
    func handleImageTap(_ tapGesture: UITapGestureRecognizer) {
        guard message?.videoUrl == nil else { return }
        guard let imageView = tapGesture.view as? UIImageView else {
            print("error: unable to fetch a UIImageView from tapGesture!")
            return
        }
        delegate?.preformZoomIn(forStartingImageView: imageView)
    }
    var bubbleViewWidthAnchor: NSLayoutConstraint?
    var bubbleViewRightAnchor: NSLayoutConstraint?
    var bubbleViewLeftAnchor: NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(bubbleView)
        
        bubbleView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        bubbleViewWidthAnchor = bubbleView.widthAnchor.constraint(equalToConstant: 200)
        bubbleViewWidthAnchor?.isActive = true
        bubbleView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        
        
        bubbleViewLeftAnchor = bubbleView.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8)
        bubbleViewRightAnchor = bubbleView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -8)
        
        addSubview(textView)
        
        textView.rightAnchor.constraint(equalTo: bubbleView.rightAnchor).isActive = true
        textView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor, constant: 8).isActive = true
        textView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        textView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        
        addSubview(profileImageView)
        
        profileImageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8).isActive = true
        profileImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 32).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 32).isActive = true
        
        bubbleView.addSubview(messageImageView)
        
        messageImageView.topAnchor.constraint(equalTo: bubbleView.topAnchor).isActive = true
        messageImageView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor).isActive = true
        messageImageView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor).isActive = true
        messageImageView.rightAnchor.constraint(equalTo: bubbleView.rightAnchor).isActive = true
        
        bubbleView.addSubview(playButton)
        playButton.topAnchor.constraint(equalTo: messageImageView.topAnchor).isActive = true
        playButton.rightAnchor.constraint(equalTo: messageImageView.rightAnchor).isActive = true
        playButton.bottomAnchor.constraint(equalTo: messageImageView.bottomAnchor).isActive = true
        playButton.leftAnchor.constraint(equalTo: messageImageView.leftAnchor).isActive = true
        
        bubbleView.addSubview(activityIndicatorView)
        activityIndicatorView.topAnchor.constraint(equalTo: messageImageView.topAnchor).isActive = true
        activityIndicatorView.rightAnchor.constraint(equalTo: messageImageView.rightAnchor).isActive = true
        activityIndicatorView.bottomAnchor.constraint(equalTo: messageImageView.bottomAnchor).isActive = true
        activityIndicatorView.leftAnchor.constraint(equalTo: messageImageView.leftAnchor).isActive = true
        

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        playerLayer?.removeFromSuperlayer()
        player?.pause()
        activityIndicatorView.stopAnimating()
    }
    
}
