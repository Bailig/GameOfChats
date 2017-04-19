//
//  LoginController+Handlers.swift
//  GameOfChats
//
//  Created by Bailig Abhanar on 2017-04-17.
//  Copyright © 2017 Bailig Abhanar. All rights reserved.
//

import UIKit
import Firebase

extension LoginController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func handleSelectProfileImage() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        
        present(picker, animated: true, completion: nil)
    }
    
    func handleLoginRegister() {
        switch loginRegisterSegmentedControl.selectedSegmentIndex {
        case 0:
            handleLogin()
        case 1:
            handleRegistor()
        default:
            break
        }
    }
    
    func handleLogin() {
        guard let email = emailTextFiled.text, let password = passwordTextFiled.text else {
            print("error: unable to fetch email or password!")
            return
        }
        FIRAuth.auth()?.signIn(withEmail: email, password: password, completion: { (user: FIRUser?, error) in
            if let error = error {
                print("error: \(error.localizedDescription)")
                return
            }
            
            if let uid = user?.uid {
                self.uid = uid
                self.delegate?.fetchUserAndSetNavBarTitle(withUid: uid)
            }
            
            self.dismiss(animated: true, completion: nil)
        })
    }
    
    func handleRegistor() {
        guard let email = emailTextFiled.text, let password = passwordTextFiled.text, let name = nameTextFiled.text else {
            print("error: unable to fetch email or password!")
            return
        }
        // authorize user
        FIRAuth.auth()?.createUser(withEmail: email, password: password, completion: { (user: FIRUser?, error) in
            if let error = error {
                print("error: \(error.localizedDescription)")
                return
            }
            guard let uid = user?.uid else {
                print("error: unable to fetch the user!")
                return
            }
            // storage user profile image
            // let uniqueImageName = NSUUID().uuidString
            let storageRef = FIRStorage.storage().reference().child("profile_image_for_uid").child("\(uid).jpg")
            
            if let image = self.profileImageView.image, let uploadData = UIImageJPEGRepresentation(image, 0.1) {
                
                storageRef.put(uploadData, metadata: nil, completion: { (metadata: FIRStorageMetadata?, error) in
                    if let error = error {
                        print("error \(error.localizedDescription)")
                        return
                    }
                    
                    if let profileImageUrl = metadata?.downloadURL()?.absoluteString {
                        // create user profile info name, email, and profileImageUrl
                        let values = ["name": name, "email": email, "profileImageUrl": profileImageUrl]
                        self.registerUserProfileIntoDatabase(withUid: uid, values: values)
                    }
                })
            }
        })
    }
    
    private func registerUserProfileIntoDatabase(withUid uid: String, values: [String: Any]) {
        let ref = FIRDatabase.database().reference()
        let userRef = ref.child("users").child(uid)
        
        userRef.updateChildValues(values, withCompletionBlock: { (error, ref: FIRDatabaseReference) in
            if let error = error {
                print("error: \(error.localizedDescription)")
                return
            }
            let user = User()
            user.setValuesForKeys(values)
            
            self.delegate?.fetchUserAndSetNavBarTitle(withUid: uid)
            self.dismiss(animated: true, completion: nil)
        })
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        /* example when imagePickerController.allowEditing = false:
         info = [
             "UIImagePickerControllerMediaType": public.image,
             "UIImagePickerControllerReferenceURL": assets-library://asset/asset.JPG?id=106E99A1-4F6A-45A2-B320-B0AD4A8E8473&ext=JPG, 
             "UIImagePickerControllerOriginalImage": <UIImage: 0x600000289ab0> size {4288, 2848} orientation 0 scale 1.000000
         ]
        */
        /* example when imagePickerController.allowEditing = true:
         info = [
             "UIImagePickerControllerEditedImage": <UIImage: 0x60800009f810> size {1242, 1242} orientation 0 scale 1.000000,
             "UIImagePickerControllerMediaType": public.image, "UIImagePickerControllerCropRect": NSRect: {{1160, 358}, {2089, 2089}}, 
             "UIImagePickerControllerReferenceURL": assets-library://asset/asset.JPG?id=106E99A1-4F6A-45A2-B320-B0AD4A8E8473&ext=JPG, 
             "UIImagePickerControllerOriginalImage": <UIImage: 0x608000281220> size {4288, 2848} orientation 0 scale 1.000000
         ]
         */
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            selectedImageFromPicker = editedImage
        } else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            selectedImageFromPicker = originalImage
        } else {
            print("error: unable to fetch picked image!")
        }
        
        if let selectedImage = selectedImageFromPicker {
            profileImageView.image = selectedImage
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // dismiss image picker view
        dismiss(animated: true, completion: nil)
    }
    
}
