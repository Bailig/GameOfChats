//
//  LoginController.swift
//  GameOfChats
//
//  Created by Bailig Abhanar on 2017-04-16.
//  Copyright © 2017 Bailig Abhanar. All rights reserved.
//

import UIKit
import Firebase

class LoginController: UIViewController {

    var messagesController: MessagesController?
    
    // create container view for inputs
    let inputsContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.white
        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
        return view
    }()
    
    let loginRegisterButton: UIButton = { // add lazy?
        let button = UIButton(type: UIButtonType.system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(UIColor.white, for: .normal)
        button.backgroundColor = UIColor(r: 80, g: 101, b: 161)
        button.setTitle("Register", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        
        button.addTarget(self, action: #selector(handleLoginRegister), for: .touchUpInside)
        return button
    }()
    
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
            
            guard let _ = user?.uid else {
                print("error: unable to fetch user uid!")
                return
            }
            
            self.messagesController?.fetchUserAndSetNavBarTitle()
            self.dismiss(animated: true, completion: nil)
        })
    }
    
    
    let nameTextFiled: UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.placeholder = "Name"
        return tf
    }()
    
    let nameSeparatorView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(r: 220, g: 220, b: 220)
        return view
    }()
    
    let emailTextFiled: UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.placeholder = "Email"
        return tf
    }()
    
    let emailSeparatorView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(r: 220, g: 220, b: 220)
        return view
    }()
    
    let passwordTextFiled: UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.placeholder = "Password"
        tf.isSecureTextEntry = true
        return tf
    }()
    
    lazy var profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "gameofthrones_splash")
        imageView.contentMode = .scaleAspectFill
        
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleSelectProfileImage)))
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
    let loginRegisterSegmentedControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Login", "Register"])
        sc.translatesAutoresizingMaskIntoConstraints = false
        sc.tintColor = UIColor.white
        sc.selectedSegmentIndex = 1
        
        sc.addTarget(self, action: #selector(handleLoginRegisterChange), for: .valueChanged)
        return sc
    }()
    
    func handleLoginRegisterChange() {
        let title = loginRegisterSegmentedControl.titleForSegment(at: loginRegisterSegmentedControl.selectedSegmentIndex)
        loginRegisterButton.setTitle(title, for: .normal)
        
        nameTextFieldHeightAncher?.isActive = false
        emailTextFiledHeightAncher?.isActive = false
        passwordTextFiledHeightAncher?.isActive = false
        
        switch loginRegisterSegmentedControl.selectedSegmentIndex {
        case 0:
            // change height of inputsContainerView
            inputsContainerViewHeightAnchor?.constant = 100
            
            // change height of nameTextField
            nameTextFieldHeightAncher = nameTextFiled.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 0)
            nameTextFiled.isHidden = true
            
            // change height of emailTextFiled
            emailTextFiledHeightAncher = emailTextFiled.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1/2)
            
            // change height of passwordTextFiled
            passwordTextFiledHeightAncher = passwordTextFiled.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1/2)

        case 1:
            // change height of inputsContainerView
            inputsContainerViewHeightAnchor?.constant = 150
            
            // change height of nameTextField
            nameTextFieldHeightAncher = nameTextFiled.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1/3)
            nameTextFiled.isHidden = false
            
            // change height of emailTextFiled
            emailTextFiledHeightAncher = emailTextFiled.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1/3)
            
            // change height of passwordTextFiled
            passwordTextFiledHeightAncher = passwordTextFiled.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1/3)
        default:
            break
        }
        
        emailTextFiledHeightAncher?.isActive = true
        passwordTextFiledHeightAncher?.isActive = true
        nameTextFieldHeightAncher?.isActive = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(r: 61, g: 91, b: 151)
        
        // add views
        view.addSubview(loginRegisterButton)
        view.addSubview(inputsContainerView)
        view.addSubview(profileImageView)
        view.addSubview(loginRegisterSegmentedControl)
        
        // setup views
        setupInputsContainerView()
        setupLoginRegisterButton()
        setupProfileImageView()
        setupLoginRegisterSegmentedControl()
    }
    
    func setupLoginRegisterSegmentedControl() {
        loginRegisterSegmentedControl.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loginRegisterSegmentedControl.bottomAnchor.constraint(equalTo: inputsContainerView.topAnchor, constant: -12).isActive = true
        loginRegisterSegmentedControl.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        loginRegisterSegmentedControl.heightAnchor.constraint(equalToConstant: 36).isActive = true
    }
    
    
    var inputsContainerViewHeightAnchor: NSLayoutConstraint?
    var nameTextFieldHeightAncher: NSLayoutConstraint?
    var emailTextFiledHeightAncher: NSLayoutConstraint?
    var passwordTextFiledHeightAncher: NSLayoutConstraint?
    
    
    func setupInputsContainerView() {
        // add x, y, width, height constraints
        // center = center of the view
        inputsContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        inputsContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        // width = width of view - 24
        inputsContainerView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -24).isActive = true
        
        // height = 150
        inputsContainerViewHeightAnchor = inputsContainerView.heightAnchor.constraint(equalToConstant: 150)
        inputsContainerViewHeightAnchor?.isActive = true
        
        // add subviews
        inputsContainerView.addSubview(nameTextFiled)
        inputsContainerView.addSubview(nameSeparatorView)
        inputsContainerView.addSubview(emailTextFiled)
        inputsContainerView.addSubview(emailSeparatorView)
        inputsContainerView.addSubview(passwordTextFiled)
        
        
        // set sub views
        nameTextFiled.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor, constant: 12).isActive = true
        nameTextFiled.topAnchor.constraint(equalTo: inputsContainerView.topAnchor).isActive = true
        nameTextFiled.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor, constant: -24).isActive = true
        nameTextFieldHeightAncher = nameTextFiled.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1/3)
        nameTextFieldHeightAncher?.isActive = true
        
        nameSeparatorView.topAnchor.constraint(equalTo: nameTextFiled.bottomAnchor).isActive = true
        nameSeparatorView.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor).isActive = true
        nameSeparatorView.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        nameSeparatorView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        emailTextFiled.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor, constant: 12).isActive = true
        emailTextFiled.topAnchor.constraint(equalTo: nameSeparatorView.bottomAnchor).isActive = true
        emailTextFiled.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor, constant: -24).isActive = true
        emailTextFiledHeightAncher = emailTextFiled.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1/3)
        emailTextFiledHeightAncher?.isActive = true
        
        emailSeparatorView.topAnchor.constraint(equalTo: emailTextFiled.bottomAnchor).isActive = true
        emailSeparatorView.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor).isActive = true
        emailSeparatorView.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        emailSeparatorView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        passwordTextFiled.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor, constant: 12).isActive = true
        passwordTextFiled.topAnchor.constraint(equalTo: emailSeparatorView.bottomAnchor).isActive = true
        passwordTextFiled.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor, constant: -24).isActive = true
        passwordTextFiledHeightAncher = passwordTextFiled.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1/3)
        passwordTextFiledHeightAncher?.isActive = true
    }
    
    func setupLoginRegisterButton() {
        // add x, top y, width, height constraints
        // x center = x center of the view
        loginRegisterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        // top y position = bottom y position of inputsContainerView + 12
        loginRegisterButton.topAnchor.constraint(equalTo: inputsContainerView.bottomAnchor, constant: 12).isActive = true
        
        // width = width of inputsContainerView
        loginRegisterButton.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        
        // height = 30
        loginRegisterButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
    }
    
    func setupProfileImageView() {
        profileImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        profileImageView.bottomAnchor.constraint(equalTo: loginRegisterSegmentedControl.topAnchor, constant: -12).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 150).isActive = true
        profileImageView.heightAnchor.constraint(equalTo: profileImageView.widthAnchor).isActive = true
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        // set status bar elements, like battery icon, with white border rather then black.
        return .lightContent
    }
}





















