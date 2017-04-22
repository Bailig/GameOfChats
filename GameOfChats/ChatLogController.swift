//
//  ChatLogController.swift
//  GameOfChats
//
//  Created by Bailig Abhanar on 2017-04-18.
//  Copyright © 2017 Bailig Abhanar. All rights reserved.
//

import UIKit
import Firebase

class ChatLogController: UICollectionViewController, UITextFieldDelegate, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var ref: FIRDatabaseReference?
    var chatPartner: User? {
        didSet {
            navigationItem.title = chatPartner?.name
            observeMessagesForChatPartnerUser()
        }
    }
    
    var messages = [Message]()
    let cellId = "cellId"
    var imageZoomStartingFrame: CGRect?
    var imageZoomBlackBackgroundView: UIView?
    
    
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
        
        setupKeyBoardObserver()
    }
    
    func setupKeyBoardObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyBoardDidShow), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
    }
    func handleKeyBoardDidShow() {
        guard messages.count > 0 else { return }
        let indexPath = IndexPath(item: messages.count - 1, section: 0)
        collectionView?.scrollToItem(at: indexPath, at: .top, animated: true)
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
                
                let message = Message(dictionary: dictionary)
                message.id = messageId
                self.messages.append(message)
                DispatchQueue.main.async {
                    self.collectionView?.reloadData()
                    // scroll to the last index
                    let indexPath = IndexPath(item: self.messages.count - 1, section: 0)
                    self.collectionView?.scrollToItem(at: indexPath, at: .bottom, animated: true)
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
        
        let uploadImageView = UIImageView()
        uploadImageView.translatesAutoresizingMaskIntoConstraints = false
        uploadImageView.image = UIImage(named: "upload_image_icon")
        uploadImageView.isUserInteractionEnabled = true
        uploadImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleUploadImage)))
        containerView.addSubview(uploadImageView)
        uploadImageView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        uploadImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        uploadImageView.widthAnchor.constraint(equalToConstant: 44).isActive = true
        uploadImageView.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
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
        self.inputTextField.leftAnchor.constraint(equalTo: uploadImageView.rightAnchor, constant: 8).isActive = true
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
        guard let text = inputTextField.text, !text.isEmpty else {
            print("error: unable to fetch text from user input!")
            return
        }
        let properties: [String: Any] = ["text": text]
        sendMessage(withProperties: properties)
        inputTextField.text = nil
    }
    
    func handleUploadImage() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        
        present(imagePickerController, animated: true, completion: nil)
        
    }
    
    // MARK: - image picker controller
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {

        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            selectedImageFromPicker = editedImage
        } else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            selectedImageFromPicker = originalImage
        } else {
            print("error: unable to fetch picked image!")
        }
        
        if let selectedImage = selectedImageFromPicker {
            uploadToFirebaseStorage(usingImage: selectedImage)
        }
        dismiss(animated: true, completion: nil)
    }
    
    private func uploadToFirebaseStorage(usingImage image: UIImage) {
        let uniqueImageName = NSUUID().uuidString
        let messageImageRef = FIRStorage.storage().reference().child("message_image").child("\(uniqueImageName).jpg")
        
        if let uploadData = UIImageJPEGRepresentation(image, 0.2) {
            messageImageRef.put(uploadData, metadata: nil, completion: { (metadata, error) in
                if let error = error {
                    print("error: \(error.localizedDescription)")
                    return
                }
                if let imageUrl = metadata?.downloadURL()?.absoluteString {
                    
                    self.sendMessage(withImageUrl: imageUrl, image: image)
                }
            })
        }
    }
    
    func sendMessage(withImageUrl imageUrl: String, image: UIImage) {
        let properties: [String: Any] = ["imageUrl": imageUrl, "imageWidth": image.size.width, "imageHeight": image.size.height]

        sendMessage(withProperties: properties)
    }
    
    private func sendMessage(withProperties properties: [String: Any]) {
        guard let ref = ref else {
            print("error: unexpected nil for ref: FIRDatabaseReference")
            return
        }
        let fromUid = FIRAuth.auth()?.currentUser?.uid ?? ""
        let toUid = chatPartner?.id ?? ""
        let messagesChildRef = ref.child("messages").childByAutoId()
        var values: [String: Any] = ["fromUid": fromUid, "toUid": toUid, "timestamp": NSDate().timeIntervalSince1970]
        properties.forEach { (dic: (key: String, value: Any)) in
            values[dic.key] = dic.value
        }
        
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
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - collection view
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as? ChatMessageCell else {
            print("error: unable to dequeqe reusable cell!")
            return UICollectionViewCell()
        }
        cell.delegate = self
        cell.message = messages[indexPath.item]
        cell.chatPartner = chatPartner
        if let text = cell.message?.text {
            cell.bubbleViewWidthAnchor?.constant = estimatedFrame(forText: text).width + 32
            cell.textView.isHidden = false
        } else if cell.message?.imageUrl != nil {
            cell.bubbleViewWidthAnchor?.constant = 200
            cell.textView.isHidden = true
        }
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 80
        let width = UIScreen.main.bounds.width
        
        let message = messages[indexPath.item]
        if let text = message.text {
            height = estimatedFrame(forText: text).height + 20
        } else if let imageWidth = message.imageWidth, let imageHeight = message.imageHeight {
            height = CGFloat(imageHeight * 200 / imageWidth)
            
            // height/200 = imageheight/ imagewidth
            // height * imagewidth = 200 * imageheight
            // height = 200 * imageheight / imagewidth
        }
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

extension ChatLogController: ChatMessageCellDelegate {
    func preformZoomIn(forStartingImageView imageView: UIImageView) {
        // 1. add a view on top of the tapped image
        
        // get the frame of tapped image
        if let startingFrame = imageView.superview?.convert(imageView.frame, to: nil) {
            
            imageZoomStartingFrame = startingFrame
            
            // create a new image view on top of it
            let zoomingImageView = UIImageView(frame: startingFrame)
            zoomingImageView.image = imageView.image
            zoomingImageView.isUserInteractionEnabled = true
            zoomingImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleZoomOut)))
            
            if let keyWindow = UIApplication.shared.keyWindow {
                
                // create black background
                imageZoomBlackBackgroundView = UIView(frame: keyWindow.frame)
                imageZoomBlackBackgroundView?.backgroundColor = UIColor.black
                imageZoomBlackBackgroundView?.alpha = 0
                if let imageZoomBlackBackgroundView = imageZoomBlackBackgroundView {
                    keyWindow.addSubview(imageZoomBlackBackgroundView)
                }
                
                keyWindow.addSubview(zoomingImageView)
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                    
                    self.imageZoomBlackBackgroundView?.alpha = 1
                    self.inputsContainerView.alpha = 0
                    // calculate height of the image when it's zoomed
                    let height = keyWindow.frame.width * startingFrame.height / startingFrame.width
                    zoomingImageView.frame = CGRect(x: 0, y: 0, width: keyWindow.frame.width, height: height)
                    zoomingImageView.center = keyWindow.center
                    
                }, completion: nil)
            }
        }
        
    }
    
    func handleZoomOut(_ tapGesture: UITapGestureRecognizer) {
        guard let zoomOutImageView = tapGesture.view as? UIImageView else {
            print("error: unable to fetch zoomOutImageView from gesture recognizer!")
            return
        }
        zoomOutImageView.clipsToBounds = true
        zoomOutImageView.layer.cornerRadius = 16
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: { 
            if let startingFrame = self.imageZoomStartingFrame {
                zoomOutImageView.frame = startingFrame
            }
            self.imageZoomBlackBackgroundView?.alpha = 0
            self.inputsContainerView.alpha = 1
        }) { (completed) in
            zoomOutImageView.removeFromSuperview()
        }
    }
}
