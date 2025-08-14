//
//  CallViewController.swift
//  OwnLinPhone
//
//  Created by Haidarov N on 8/12/25.
//

import UIKit

class CallViewController: UIViewController, CallDelegate {
    private let calleeField = UITextField()
    private let callButton = UIButton(type: .system)
    private let hangupButton = UIButton(type: .system)
    private let infoLabel = UILabel()

    private let callerID: String
    private let domain: String

    init(callerID: String, domain: String) {
        self.callerID = callerID
        self.domain = domain
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        LinphoneManager.shared.delegate = self
        view.backgroundColor = .systemBackground
        setupUI()
    }

    private func setupUI() {
        calleeField.placeholder = "sip target (e.g. 6002@192.168.0.10)"
        calleeField.text = "1012@192.168.43.47"
        calleeField.borderStyle = .roundedRect
        calleeField.autocapitalizationType = .none

        callButton.setTitle("Call", for: .normal)
        callButton.addTarget(self, action: #selector(callTapped), for: .touchUpInside)

        hangupButton.setTitle("Hangup", for: .normal)
        hangupButton.addTarget(self, action: #selector(hangupTapped), for: .touchUpInside)

        infoLabel.text = "Logged as: \(callerID)@\(domain)"
        infoLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [infoLabel, calleeField, callButton, hangupButton])
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

    @objc private func callTapped() {
        let target = calleeField.text ?? ""
        guard !target.isEmpty else { return }
        LinphoneManager.shared.makeCall(to: target)
        infoLabel.text = "Calling \(target) ..."
    }

    @objc private func hangupTapped() {
        LinphoneManager.shared.hangUp()
        infoLabel.text = "Hung up"
    }
    
    func incomingCallReceived() {
         DispatchQueue.main.async {
             let alert = UIAlertController(title: "Входящий звонок", message: "Принять вызов?", preferredStyle: .alert)
             alert.addAction(UIAlertAction(title: "Принять", style: .default) { _ in
                 LinphoneManager.shared.acceptCall()
             })
             alert.addAction(UIAlertAction(title: "Отказать", style: .destructive) { _ in
                 LinphoneManager.shared.hangUp()
             })
             self.present(alert, animated: true)
         }
     }

     func callEnded() {
         DispatchQueue.main.async {
             // Обновите UI, уберите экран звонка и т.п.
             print("Вызов завершён")
         }
     }
}
