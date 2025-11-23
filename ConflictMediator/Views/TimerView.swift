import SwiftUI

enum DisplayMode {
    case normal
    case splitScreen
}

struct TimerView: View {
    @ObservedObject var session: SessionModel
    @State private var showResetConfirmation = false
    @State private var displayMode: DisplayMode = .normal

    var body: some View {
        if displayMode == .splitScreen {
            ZStack {
                SplitScreenTimerView(session: session)

                // 모드 전환 버튼 (양면 모드에서)
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            displayMode = .normal
                        }) {
                            Image(systemName: "rectangle")
                                .padding(12)
                                .background(Color.black.opacity(0.6))
                                .foregroundColor(.white)
                                .clipShape(Circle())
                        }
                        .padding()
                    }
                    Spacer()
                }
            }
            .alert("세션 초기화", isPresented: $showResetConfirmation) {
                Button("취소", role: .cancel) { }
                Button("초기화", role: .destructive) {
                    session.resetSession()
                }
            } message: {
                Text("모든 타이머와 기록이 초기화됩니다. 계속하시겠습니까?")
            }
            .alert(session.currentPrompt, isPresented: $session.showMediationPrompt) {
                Button("확인", role: .cancel) { }
            } message: {
                Text("중재 제안")
            }
        } else {
            normalModeView
        }
    }

    var normalModeView: some View {
        NavigationView {
            VStack(spacing: 20) {
                HStack {
                    Text("세션 상태:")
                        .font(.headline)
                    Text(session.isActive ? "진행 중" : "일시정지")
                        .foregroundColor(session.isActive ? .green : .orange)
                        .fontWeight(.bold)
                }
                .padding()
                
                VStack(spacing: 10) {
                    Text("발화 시간 균형")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    GeometryReader { geometry in
                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: geometry.size.width * session.timeBalancePercentage())
                            
                            Rectangle()
                                .fill(Color.green)
                                .frame(width: geometry.size.width * (1 - session.timeBalancePercentage()))
                        }
                    }
                    .frame(height: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal)
                    
                    HStack {
                        Text("A: \(Int(session.timeBalancePercentage() * 100))%")
                            .foregroundColor(.blue)
                        Spacer()
                        Text("B: \(Int((1 - session.timeBalancePercentage()) * 100))%")
                            .foregroundColor(.green)
                    }
                    .font(.caption)
                    .padding(.horizontal)
                }
                .frame(height: 80)
                
                HStack(spacing: 20) {
                    SpeakerTimerCard(
                        name: "사람 A",
                        time: session.timeString(from: session.personATime),
                        color: .blue,
                        isActive: session.currentSpeaker == .personA,
                        action: {
                            if session.currentSpeaker == .personA {
                                session.pauseSession()
                            } else {
                                session.switchSpeaker(to: .personA)
                            }
                        }
                    )
                    
                    SpeakerTimerCard(
                        name: "사람 B",
                        time: session.timeString(from: session.personBTime),
                        color: .green,
                        isActive: session.currentSpeaker == .personB,
                        action: {
                            if session.currentSpeaker == .personB {
                                session.pauseSession()
                            } else {
                                session.switchSpeaker(to: .personB)
                            }
                        }
                    )
                }
                .padding(.horizontal)
                
                Spacer()

                VStack(spacing: 15) {
                    // 시작 안내 텍스트
                    if session.currentSpeaker == .none {
                        Text("사람을 탭해서 대화를 시작해주세요")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    Button(action: {
                        if session.isActive {
                            session.pauseSession()
                        } else {
                            session.startSession()
                        }
                    }) {
                        HStack {
                            Image(systemName: session.isActive ? "pause.fill" : "play.fill")
                            Text(session.isActive ? "일시정지" : "재개")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(session.isActive ? Color.orange : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(session.currentSpeaker == .none)
                    
                    Button(action: {
                        showResetConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("세션 초기화")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding()
            }
            .navigationTitle("대화 타이머")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        displayMode = displayMode == .normal ? .splitScreen : .normal
                    }) {
                        Image(systemName: displayMode == .normal ? "rectangle.split.2x1" : "rectangle")
                            .imageScale(.large)
                    }
                }
            }
            .alert("세션 초기화", isPresented: $showResetConfirmation) {
                Button("취소", role: .cancel) { }
                Button("초기화", role: .destructive) {
                    session.resetSession()
                }
            } message: {
                Text("모든 타이머와 기록이 초기화됩니다. 계속하시겠습니까?")
            }
            .alert(session.currentPrompt, isPresented: $session.showMediationPrompt) {
                Button("확인", role: .cancel) { }
            } message: {
                Text("중재 제안")
            }
        }
    }
}

struct SpeakerTimerCard: View {
    let name: String
    let time: String
    let color: Color
    let isActive: Bool
    let action: () -> Void
    @State private var blinkOpacity: Double = 1.0

    var body: some View {
        Button(action: action) {
            VStack(spacing: 15) {
                Text(name)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(time)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(color)

                if isActive {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                        Text("말하는 중")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("탭하여 시작")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .opacity(blinkOpacity)
                        .onAppear {
                            withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                                blinkOpacity = 0.3
                            }
                        }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 30)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(isActive ? color.opacity(0.1) : Color(UIColor.systemBackground))
                    .shadow(color: isActive ? color.opacity(0.3) : Color.black.opacity(0.1), radius: isActive ? 10 : 5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(isActive ? color : Color.clear, lineWidth: 3)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SplitScreenTimerView: View {
    @ObservedObject var session: SessionModel

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    // 사람 A 영역 (180도 회전 - 윗쪽에서 보는 사람용)
                    SinglePersonTimerView(
                        session: session,
                        person: .personA,
                        personName: "사람 A",
                        personTime: session.personATime,
                        color: .blue
                    )
                    .frame(height: geometry.size.height / 2)
                    .rotationEffect(.degrees(180))

                    // 사람 B 영역 (정상 방향 - 아랫쪽에서 보는 사람용)
                    SinglePersonTimerView(
                        session: session,
                        person: .personB,
                        personName: "사람 B",
                        personTime: session.personBTime,
                        color: .green
                    )
                    .frame(height: geometry.size.height / 2)
                }

                // 중앙 일시정지/재개 버튼
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            if session.isActive {
                                session.pauseSession()
                            } else {
                                session.startSession()
                            }
                        }) {
                            Image(systemName: session.isActive ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                                .background(
                                    Circle()
                                        .fill(session.isActive ? Color.orange : Color.blue)
                                        .frame(width: 60, height: 60)
                                )
                                .shadow(color: Color.black.opacity(0.3), radius: 10)
                        }
                        .disabled(session.currentSpeaker == .none)
                        .opacity(session.currentSpeaker == .none ? 0.5 : 1.0)
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct SinglePersonTimerView: View {
    @ObservedObject var session: SessionModel
    let person: Speaker
    let personName: String
    let personTime: TimeInterval
    let color: Color
    @State private var blinkOpacity: Double = 1.0

    var isActive: Bool {
        session.currentSpeaker == person
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // 상단 여백 (safe area 고려 - 더 넉넉하게)
                Spacer()
                    .frame(height: max(geometry.safeAreaInsets.top + 40, 60))

                Spacer()

                // 타이머 표시
                VStack(spacing: 10) {
                    Text(personName)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(session.timeString(from: personTime))
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .foregroundColor(color)

                    if isActive {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 12, height: 12)
                            Text("말하는 중")
                                .font(.headline)
                        }
                    }
                }

                Spacer()

                // 컨트롤 영역 (버튼 대신 안내 텍스트만)
                VStack(spacing: 12) {
                    // 시작 안내 텍스트 (반짝임 효과)
                    if !isActive {
                        Text("화면을 터치하여 시작")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(color)
                            .opacity(blinkOpacity)
                            .onAppear {
                                withAnimation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                                    blinkOpacity = 0.3
                                }
                            }
                    }

                    // 발화 시간 비율 표시
                    let percentage = person == .personA ?
                        Int(session.timeBalancePercentage() * 100) :
                        Int((1 - session.timeBalancePercentage()) * 100)

                    Text("발화 비율: \(percentage)%")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 20)

                // 하단 여백 (safe area 고려 - 더 넉넉하게)
                Spacer()
                    .frame(height: max(geometry.safeAreaInsets.bottom + 40, 60))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(isActive ? color.opacity(0.05) : Color(UIColor.systemBackground))
            .contentShape(Rectangle())
            .onTapGesture {
                if session.currentSpeaker == person {
                    // 이미 말하고 있으면 아무것도 안 함 (중앙 버튼으로 일시정지)
                } else {
                    // 상대방이 말하고 있거나 아무도 안 말하면 턴 전환
                    session.switchSpeaker(to: person)
                }
            }
        }
    }
}

#Preview {
    TimerView(session: SessionModel())
}
