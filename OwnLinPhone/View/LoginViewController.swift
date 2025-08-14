//
//  LoginViewController.swift
//  OwnLinPhone
//
//  Created by Haidarov N on 8/12/25.
//

import UIKit
import SwiftUI


class LoginViewController: UIViewController {
    private let usernameField = UITextField()
    private let passwordField = UITextField()
    private let domainField = UITextField()
    private let registerButton = UIButton(type: .system)
    private let statusLabel = UILabel()
    let loading = UIActivityIndicatorView(style: .medium)
    

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .gray
        setupUI()
        LinphoneManager.shared.start()
    }

    private func setupUI() {
        loading.color = .white
        loading.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(loading)

        NSLayoutConstraint.activate([
            loading.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -200),
            loading.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        usernameField.placeholder = "SIP username (e.g. 6001)"
        usernameField.text = "10111"
        usernameField.borderStyle = .roundedRect
        usernameField.autocapitalizationType = .none
        usernameField.keyboardType = .numberPad

        passwordField.placeholder = "Password"
        passwordField.text = "10111"
        passwordField.borderStyle = .roundedRect
        passwordField.isSecureTextEntry = true

        domainField.placeholder = "Domain or IP (e.g. 192.168.0.10)"
        domainField.text = "192.168.43.47"
        
        domainField.borderStyle = .roundedRect
        domainField.autocapitalizationType = .none

        registerButton.setTitle("Register", for: .normal)
        registerButton.setTitleColor(.white, for: .normal)
        registerButton.addTarget(self, action: #selector(registerTapped), for: .touchUpInside)

        statusLabel.text = "Not registered"
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 2

        let stack = UIStackView(arrangedSubviews: [usernameField, passwordField, domainField, registerButton, statusLabel])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
       
    
    }

    @objc private func registerTapped() {
        let user = usernameField.text ?? ""
        let pass = passwordField.text ?? ""
        let domain = domainField.text ?? ""
        statusLabel.text = "Registering..."
        registerButton.isEnabled = false
        loading.startAnimating()

        LinphoneManager.shared.registerAccount(username: user, password: pass, domain: domain){ succes in
            self.loading.stopAnimating()
            self.registerButton.isEnabled = true
            if succes {
                self.statusLabel.text = "Registered: \(user)@\(domain)"
                // push Call screen
                let callVC = UIHostingController(rootView: CallView(domen: domain, user: user))
                self.navigationController?.pushViewController(callVC, animated: true)
                print("registration succes")
            }else{
                print("registration failure")
                self.statusLabel.text = "Registration: failure"
                
                
            }
        }
    }
}
