import Foundation
import UIKit
import linphone
import linphonesw
import AVFoundation

protocol CallDelegate: AnyObject {
    func incomingCallReceived()
    func callEnded()
}

final class LinphoneManager: ObservableObject {

    // MARK: - Published (UI)
    @Published var currentIncomingCall: OpaquePointer?
    @Published var callDuration: String = "00:00"
    @Published var isCallActive: Bool = false
    @Published var isMicMuted: Bool = false
    @Published var isSpeakerOn: Bool = false
    @Published var isRegistered: Bool = false
    @Published var lastRegistrationMessage: String?

    // MARK: - Core
    static let shared = LinphoneManager()
    private(set) var core: OpaquePointer?

    // MARK: - Timers
    private var coreIterateTimer: Timer?
    private var callDurationTimer: Timer?
    private var callStartTime: Date?

    // MARK: - Callbacks & vtable
    private var registerCompletion: ((Bool) -> Void)?
    private var vtable = LinphoneCoreVTable()

    weak var delegate: CallDelegate?

    private init() {}

    deinit {
        stop()
    }

    // MARK: - Start / Stop

    func start() {
        guard core == nil else { return }

        // 1) Audio session
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth])
            try session.setActive(true)
            print("📞 AVAudioSession activated")
        } catch {
            print("📞 AVAudioSession setup failed: \(error)")
        }

        // 2) vtable
        memset(&vtable, 0, MemoryLayout<LinphoneCoreVTable>.size)
        vtable.registration_state_changed = LinphoneManager.registrationStateChangedCallback
        vtable.call_state_changed = LinphoneManager.callStateChangedCallback

        // 3) Create core
        let factoryConfigPath = Bundle.main.path(forResource: "linphonerc-factory", ofType: nil) ?? ""
        var errorPtr: UnsafeMutablePointer<Int8>? = nil

        core = factoryConfigPath.withCString { factoryCStr in
            linphone_core_new(&vtable, factoryCStr, nil, &errorPtr)
        }

        if core == nil {
            if let err = errorPtr {
                print("📞 LinphoneCore creation error: \(String(cString: err))")
            } else {
                print("📞 LinphoneCore creation error: unknown")
            }
            return
        }

        linphone_core_set_user_agent(core, "MyApp", "1.0")

        // Включить логирование при необходимости (проверьте доступность API в вашей версии SDK)
        // linphone_core_set_log_level_mask(ORTP_DEBUG)

        // 4) iterate timer (ОТДЕЛЬНО от таймера длительности)
        coreIterateTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { [weak self] _ in
            guard let self, let core = self.core else { return }
            linphone_core_iterate(core)
        }
        RunLoop.main.add(coreIterateTimer!, forMode: .common)
    }

    func stop() {
        stopCallTimer()

        coreIterateTimer?.invalidate()
        coreIterateTimer = nil

        if let core = core {
            linphone_core_destroy(core)
            self.core = nil
        }
    }

    // MARK: - Registration

    func registerAccount(username: String, password: String, domain: String, completion: @escaping (Bool) -> Void) {
        guard let core = core else {
            print("📞 LinphoneCore is nil — cannot register")
            completion(false)
            return
        }

        registerCompletion = completion

        let identity = "sip:\(username)@\(domain)"
        print("📞 Creating LinphoneAddress for \(identity)")
        guard let identityAddr = linphone_address_new(identity) else {
            print("📞 Failed to create LinphoneAddress for identity")
            DispatchQueue.main.async {
                self.isRegistered = false
                self.lastRegistrationMessage = "Invalid identity"
            }
            completion(false)
            return
        }
        defer { linphone_address_unref(identityAddr) }

        print("📞 Creating proxy config")
        guard let proxyCfg = linphone_core_create_proxy_config(core) else {
            print("📞 Failed to create proxy config")
            DispatchQueue.main.async {
                self.isRegistered = false
                self.lastRegistrationMessage = "Proxy config error"
            }
            completion(false)
            return
        }

        print("📞 Setting identity address in proxy")
        linphone_proxy_config_set_identity_address(proxyCfg, identityAddr)

        let server = "sip:\(domain)"
        print("📞 Setting server address: \(server)")
        linphone_proxy_config_set_server_addr(proxyCfg, server)

        print("📞 Enabling registration")
        linphone_proxy_config_enable_register(proxyCfg, 1)

        print("📞 Adding auth info")
        let authInfo = linphone_auth_info_new(username, nil, password, nil, nil, domain)
        linphone_core_add_auth_info(core, authInfo)

        print("📞 Adding proxy config to core")
        linphone_core_add_proxy_config(core, proxyCfg)
        linphone_core_set_default_proxy_config(core, proxyCfg)

        print("📞 Registration requested for \(identity). Waiting for callback...")

    }

    // MARK: - Calling

    func makeCall(to sipAddress: String) {
        guard let core = core else { return }
        guard linphone_core_invite(core, sipAddress) != nil else {
            print("📞 Failed to start call to \(sipAddress)")
            return
        }
        print("📞 Calling \(sipAddress)")
    }

    func acceptCall() {
        guard let core = core else { return }
        if let call = currentIncomingCall {
            linphone_core_accept_call(core, call)
            return
        }
        if let call = linphone_core_get_current_call(core) {
            linphone_core_accept_call(core, call)
        }
    }

    func hangUp() {
        guard let core = core else { return }
        if let call = linphone_core_get_current_call(core) {
            linphone_core_terminate_call(core, call)
        } else if let incoming = currentIncomingCall {
            linphone_core_terminate_call(core, incoming)
        }
    }

    // MARK: - Audio controls

    func setSpeaker(_ on: Bool) {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.overrideOutputAudioPort(on ? .speaker : .none)
            DispatchQueue.main.async { self.isSpeakerOn = on }
        } catch {
            print("📞 Speaker toggle error: \(error)")
        }
    }

    func setMute(_ mute: Bool) {
        guard let core = core else { return }
        linphone_core_enable_mic(core, mute ? 0 : 1)
        DispatchQueue.main.async { self.isMicMuted = mute }
    }

    // MARK: - Call Duration

    private func startCallTimer() {
        callStartTime = Date()
        callDurationTimer?.invalidate()
        callDurationTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateCallDuration()
        }
        if let t = callDurationTimer {
            RunLoop.main.add(t, forMode: .common)
        }
    }

    private func stopCallTimer() {
        callDurationTimer?.invalidate()
        callDurationTimer = nil
        callStartTime = nil
        DispatchQueue.main.async { self.callDuration = "00:00" }
    }

    private func updateCallDuration() {
        guard let start = callStartTime else { return }
        let interval = Int(Date().timeIntervalSince(start))
        let minutes = interval / 60
        let seconds = interval % 60
        DispatchQueue.main.async {
            self.callDuration = String(format: "%02d:%02d", minutes, seconds)
        }
    }

    // MARK: - C callbacks -> instance

    static let registrationStateChangedCallback: @convention(c)
    (OpaquePointer?, OpaquePointer?, LinphoneRegistrationState, UnsafePointer<Int8>?) -> Void = { _, _, state, message in
        let manager = LinphoneManager.shared

        let msg = message != nil ? String(cString: message!) : nil
        DispatchQueue.main.async {
            switch state {
            case LinphoneRegistrationOk:
                manager.isRegistered = true
                manager.lastRegistrationMessage = msg ?? "OK"
                manager.registerCompletion?(true)
                manager.registerCompletion = nil

            case LinphoneRegistrationFailed, LinphoneRegistrationCleared, LinphoneRegistrationNone:
                manager.isRegistered = false
                manager.lastRegistrationMessage = msg ?? "Registration failed"
                manager.registerCompletion?(false)
                manager.registerCompletion = nil

            default:
                manager.lastRegistrationMessage = msg
            }
        }
    }

    static let callStateChangedCallback: @convention(c)
    (OpaquePointer?, OpaquePointer?, LinphoneCallState, UnsafePointer<Int8>?) -> Void = { lc, call, state, message in
        LinphoneManager.shared.handleCallStateChanged(lc: lc, call: call, state: state, message: message)
    }

    // MARK: - Call state handler

    func handleCallStateChanged(lc: OpaquePointer?, call: OpaquePointer?, state: LinphoneCallState, message: UnsafePointer<Int8>?) {
        let callDir = linphone_call_get_dir(call)
        print("📞 call")
        switch state {

        case LinphoneCallStateIncomingReceived,
             LinphoneCallStateIncomingEarlyMedia,
             LinphoneCallStatePushIncomingReceived:
            guard callDir == LinphoneCallIncoming else { return }
             guard CallManager.shared.currentCallUUID == nil else { return }
             
                 CallManager.shared.reportIncomingCall(handle: "User") { }

        case LinphoneCallStateConnected,
             LinphoneCallStateStreamsRunning:
            print("📞 Call active (media/connected)")
            startCallTimer()
            DispatchQueue.main.async { self.isCallActive = true }

        case LinphoneCallStatePaused,
             LinphoneCallStatePausedByRemote:
            print("⏸️ Call paused")
            DispatchQueue.main.async { self.isCallActive = false }

        case LinphoneCallStateResuming:
            print("▶️ Resuming")
            // ждать StreamsRunning/Connected

        case LinphoneCallStateEnd,
             LinphoneCallStateReleased,
             LinphoneCallStateError:
            print("📞 Call ended/released/error")
            stopCallTimer()
            DispatchQueue.main.async {
                self.currentIncomingCall = nil
                self.isCallActive = false
                self.callDuration = "00:00"
                CallManager.shared.callDidEnd()
            }
            delegate?.callEnded()

        default:
            // Другие состояния: Outgoing*, Updating*, Referred и т.д.
            break
        }
    }
}
