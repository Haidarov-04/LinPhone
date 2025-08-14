import Foundation
import CallKit
import linphonesw
import linphone

class CallManager: NSObject, ObservableObject {
    static let shared = CallManager()
    @Published var isCallActive: Bool = false
    private let provider: CXProvider
    private let callController = CXCallController()
    var currentCallUUID: UUID?

    override init() {
        let config = CXProviderConfiguration(localizedName: "My VoIP App")
        config.includesCallsInRecents = true
        config.supportsVideo = false
        config.maximumCallsPerCallGroup = 1
        config.supportedHandleTypes = [.phoneNumber]

        provider = CXProvider(configuration: config)
        super.init()
        provider.setDelegate(self, queue: nil)
    }

    func reportIncomingCall(handle: String, completion: @escaping () -> Void) {
        guard !handle.isEmpty else { completion(); return }
        let uuid = UUID()
        let update = CXCallUpdate()
        self.currentCallUUID = uuid
        update.remoteHandle = CXHandle(type: .phoneNumber, value: handle)
        update.hasVideo = false

        DispatchQueue.main.async {
            self.provider.reportNewIncomingCall(with: uuid, update: update) { error in
                if error == nil {
                    self.currentCallUUID = uuid
                } else {
                    print("CallKit incoming call error: \(error!)")
                }
                completion()
            }
        }
    }


    func endCall() {
        guard let uuid = currentCallUUID else { return }
        let endAction = CXEndCallAction(call: uuid)
        let transaction = CXTransaction(action: endAction)
        callController.request(transaction) { error in
            if let error = error { print("EndCall error: \(error)") }
        }
    }

    func answerCall() {
        guard let uuid = currentCallUUID else { return }
        let answerAction = CXAnswerCallAction(call: uuid)
        let transaction = CXTransaction(action: answerAction)
        callController.request(transaction) { error in
            if let error = error { print("AnswerCall error: \(error)") }
        }
    }
    
    func callDidEnd() {
        DispatchQueue.main.async {
            // Сброс состояния для SwiftUI
            self.isCallActive = false

            // Завершаем звонок CallKit, если есть активный UUID
            if let uuid = self.currentCallUUID {
                let endAction = CXEndCallAction(call: uuid)
                let transaction = CXTransaction(action: endAction)
                self.callController.request(transaction) { error in
                    if let error = error {
                        print("Failed to end CallKit call: \(error)")
                    } else {
                        print("CallKit call ended successfully")
                    }
                }
                self.currentCallUUID = nil
            }
        }
     }
}

extension CallManager: CXProviderDelegate {
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        print("User answered call via CallKit")
        // Accept Linphone call here
        LinphoneManager.shared.acceptCall()
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        print("User ended call via CallKit")
        if let call = LinphoneManager.shared.currentIncomingCall {
            linphone_core_terminate_call(LinphoneManager.shared.core, call)
        }
        self.callDidEnd()
        action.fulfill()
    }

    func providerDidReset(_ provider: CXProvider) {
        print("CallKit reset")
        self.callDidEnd()
    }
}
