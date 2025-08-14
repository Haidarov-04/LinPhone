
import SwiftUI
import AVFoundation

struct CallView: View {
    @State var runningCall: Bool = true
    @State var image: String = "Avatar"
    @State var rating: Double = 4.4
    @State var domen = ""
    @State var user = ""
    @State var caller = ""
    
    @ObservedObject var manager = LinphoneManager.shared
    
    var body: some View {
        ZStack {
            BackgroundView(runningCall: $manager.isCallActive)
                .edgesIgnoringSafeArea(.all)
            ScrollView(showsIndicators: false){
                VStack {
                    Image(systemName: "person")
                        .resizable()
                        .frame(width: 88, height: 88)
                    
                    
                    Text(user)
                        .font(.system(size: 18, weight: .medium))
                        .padding(.bottom, 0.5)
                    
                    if !manager.caller.isEmpty{
                        Text("Call with: \(manager.caller)")
                            .font(.system(size: 18, weight: .medium))
                            .padding(.bottom, 0.5)
                    }
                    if !manager.calling.isEmpty{
                        Text(manager.calling)
                            .font(.system(size: 18, weight: .medium))
                            .padding(.bottom, 0.5)
                    }
                    
                    Text(manager.callDuration)
                        .font(.system(size: 22, weight: .medium))
                        .padding(.top, 10)
                    
                    VStack(spacing: 20) {
                        TextField("ID", text: $caller)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .autocapitalization(.none)
                        
                        TextField("Domain", text: $domen)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .autocapitalization(.none)
                    }
                    .padding(.horizontal, 50)
                    
                    
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
                                manager.makeCall(to: "\(caller)@\(domen)")
                                manager.calling = "Calling to: \(caller) "
                            }
                        }) {
                            Image(systemName: manager.isCallActive ? "phone.down.fill" : "phone.fill")
                                .resizable()
                                .frame(width: manager.isCallActive ? 40 : 30, height: 20)
                                .padding(.vertical, 18)
                                .padding(.horizontal, manager.isCallActive ? 38 : 38)
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
                    .padding(.horizontal, 50)
                    
                }
            }
        }
    }
}

struct BackgroundView: View {
    @Binding var runningCall: Bool
    var body: some View {
        LinearGradient(
            gradient: runningCall ? Gradient(colors: [.blue, .blue, .white, .white, .white]) :  Gradient(colors: [.gray, .gray, .white, .white, .white]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
