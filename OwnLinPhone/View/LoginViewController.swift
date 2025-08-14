//
//  LoginViewController.swift
//  OwnLinPhone
//
//  Created by Haidarov N on 8/12/25.
//

import UIKit


class LoginViewController: UIViewController {
    private let usernameField = UITextField()
    private let passwordField = UITextField()
    private let domainField = UITextField()
    private let registerButton = UIButton(type: .system)
    private let statusLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .blue
        setupUI()
        LinphoneManager.shared.start()
    }

    private func setupUI() {
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
        domainField.text = "192.168.137.156"
        
        domainField.borderStyle = .roundedRect
        domainField.autocapitalizationType = .none

        registerButton.setTitle("Register", for: .normal)
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

        LinphoneManager.shared.registerAccount(username: user, password: pass, domain: domain){ succes in
            
            if succes {
                self.statusLabel.text = "Registered: \(user)@\(domain)"
                // push Call screen
                let callVC = CallViewController(callerID: user, domain: domain)
                self.navigationController?.pushViewController(callVC, animated: true)
                print("registration succes")
            }else{
                print("registration failure")
            }
        }
    }
}
