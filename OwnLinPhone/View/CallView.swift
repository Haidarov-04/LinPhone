
import SwiftUI
import AVFoundation

struct CallView: View {
    @State var runningCall: Bool = true
    @State var image: String = "Avatar"
    @State var desc: String = "Серебристый Opel Astra H 4326"
    @State var rating: Double = 4.4
    @State var domen = "192.168.43.47"
    @State var user = "10211"
    @State var status = ""
    
    @ObservedObject var manager = LinphoneManager.shared
    
    var body: some View {
        ZStack {
            BackgroundView(runningCall: $runningCall)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Text(status)
                Image(image)
                    .resizable()
                    .frame(width: 88, height: 88)
                
                HStack {
                    Text(String(format: "%.1f", rating))
                        .padding(.vertical, 2)
                        .padding(.leading, 6)
                    Image(systemName: "star.fill")
                        .resizable()
                        .frame(width: 14, height: 14)
                        .padding(.trailing, 6)
                }
                .background(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray, lineWidth: 1.5)
                )
                .cornerRadius(8)
                .padding(.top, -18)
                
                Text(user)
                    .font(.system(size: 18, weight: .medium))
                    .padding(.bottom, 0.5)
                Text(desc)
                    .font(.system(size: 16, weight: .light))
                
                Text(manager.callDuration)
                    .font(.system(size: 22, weight: .medium))
                    .padding(.top, 10)
                
                HStack {
                    // Speaker toggle
                    Button(action: {
                        manager.setSpeaker(!manager.isSpeakerOn)
                    }) {
                        Image(systemName: manager.isSpeakerOn ? "speaker.wave.2.circle.fill" : "speaker.wave.2.circle")
                            .resizable()
                            .frame(width: 28, height: 28)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 20)
                            .background(manager.isSpeakerOn ? .black : .gray.opacity(0.15))
                            .cornerRadius(20)
                    }
                    
                    // Call / Hangup
                    Button(action: {
                        if manager.isCallActive {
                            manager.hangUp()
                        } else {
                            manager.makeCall(to: "1012@\(domen)")
                        }
                    }) {
                        Image(systemName: manager.isCallActive ? "phone.down.fill" : "phone.fill")
                            .resizable()
                            .frame(width: 32, height: 16)
                            .padding(.vertical, 18)
                            .padding(.horizontal, 48)
                            .background(.red)
                            .cornerRadius(20)
                            .padding(.horizontal, 24)
                    }
                    
                    // Mic mute toggle
                    Button(action: {
                        manager.setMute(!manager.isMicMuted)
                    }) {
                        Image(systemName: manager.isMicMuted ? "microphone.slash" : "microphone")
                            .resizable()
                            .frame(width: 28, height: 28)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 20)
                            .background(manager.isMicMuted ? .black : .gray.opacity(0.15))
                            .cornerRadius(20)
                    }
                }
                .padding(.top, 250)
                Button(action: {
                    status = "Requesting microphone..."
                    
                    AVAudioSession.sharedInstance().requestRecordPermission { granted in
                        DispatchQueue.main.async {
                            if granted {
                                // 2. Старт LinphoneCore
                                LinphoneManager.shared.start()

                                // 3. Регистрация
                                LinphoneManager.shared.registerAccount(username: user, password: user, domain: domen) { success in
                                    DispatchQueue.main.async {
                                        if success { status = "Registered" } else { status = "Failed" }
                                    }
                                }
                            } else {
                                print("Microphone denied")
                            }
                        }
                    }

                }) {
                    Text("Register")
                        .font(.headline)
                        .foregroundColor(.black)
                }

            }
        }
    }
}

struct BackgroundView: View {
    @Binding var runningCall: Bool
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [.gray, .gray, .white, .white, .white]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
