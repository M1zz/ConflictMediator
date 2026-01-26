import SwiftUI

enum DisplayMode {
    case normal
    case splitScreen
}

struct TimerView: View {
    @ObservedObject var session: SessionModel
    var historyManager: SessionHistoryManager?
    @State private var showResetConfirmation = false
    @State private var showEndConfirmation = false
    @State private var displayMode: DisplayMode = .normal
    @State private var showGoalDetails = false

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
            .toolbar(.hidden, for: .tabBar)
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
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 12) {
                        if !session.configuration.topic.isEmpty {
                            Button(action: {
                                showGoalDetails = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "target")
                                        .foregroundColor(.blue)
                                        .font(.subheadline)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("대화 목표")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        Text(session.configuration.topic)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .lineLimit(1)
                                            .foregroundColor(.primary)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.blue)
                                            .font(.caption2)
                                        Text("상세")
                                            .font(.caption2)
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.blue.opacity(0.12))
                                        .shadow(color: Color.blue.opacity(0.2), radius: 2, x: 0, y: 1)
                                )
                                .padding(.horizontal)
                            }
                            .buttonStyle(.plain)
                        }

                        HStack {
                            HStack(spacing: 4) {
                                Text("남은 시간")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(session.sessionTimeRemainingString())
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(session.sessionTimeRemaining < 300 ? .red : .primary)
                            }

                            Spacer()

                            if session.audioRecorder.isRecording {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 6, height: 6)
                                    Text("녹음")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal)

                        VStack(spacing: 6) {
                            Text("발화 시간 균형")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            HStack(spacing: 0) {
                                Rectangle()
                                    .fill(Color.blue)
                                    .frame(width: (geometry.size.width - 32) * session.timeBalancePercentage())

                                Rectangle()
                                    .fill(Color.green)
                                    .frame(width: (geometry.size.width - 32) * (1 - session.timeBalancePercentage()))
                            }
                            .frame(height: 16)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .padding(.horizontal)

                            HStack {
                                Text("A: \(Int(session.timeBalancePercentage() * 100))%")
                                    .foregroundColor(.blue)
                                Spacer()
                                Text("B: \(Int((1 - session.timeBalancePercentage()) * 100))%")
                                    .foregroundColor(.green)
                            }
                            .font(.caption2)
                            .padding(.horizontal)
                        }

                        HStack(spacing: min(20, geometry.size.width * 0.04)) {
                            SpeakerTimerCard(
                                name: session.speakerName(for: .personA),
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
                                name: session.speakerName(for: .personB),
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

                        VStack(spacing: 8) {
                            if session.currentSpeaker == .none {
                                Text("사람을 탭해서 대화를 시작해주세요")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                    .minimumScaleFactor(0.8)
                                    .lineLimit(1)
                            }

                            HStack(spacing: 8) {
                                Button(action: {
                                    if session.isActive {
                                        session.pauseSession()
                                    } else {
                                        session.startSession()
                                    }
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: session.isActive ? "pause.fill" : "play.fill")
                                            .font(.caption)
                                        Text(session.isActive ? "일시정지" : "재개")
                                            .font(.subheadline)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(session.isActive ? Color.orange : Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                }
                                .disabled(session.currentSpeaker == .none)

                                Button(action: {
                                    showEndConfirmation = true
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "stop.fill")
                                            .font(.caption)
                                        Text("종료")
                                            .font(.subheadline)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color.orange.opacity(0.8))
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                }

                                Button(action: {
                                    showResetConfirmation = true
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "arrow.counterclockwise")
                                            .font(.caption)
                                        Text("초기화")
                                            .font(.subheadline)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color.red.opacity(0.8))
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, max(0, geometry.safeAreaInsets.bottom))
                    }
                }
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
            .alert("세션 종료", isPresented: $showEndConfirmation) {
                Button("취소", role: .cancel) { }
                Button("종료", role: .destructive) {
                    // Save session to history before ending
                    if let historyManager = historyManager {
                        let history = session.createSessionHistory()
                        historyManager.saveHistory(history)
                    }
                    session.endSession()
                }
            } message: {
                Text("세션을 종료하시겠습니까? 녹음이 저장되고 대화 기록에 추가됩니다.")
            }
            .alert(session.currentPrompt, isPresented: $session.showMediationPrompt) {
                Button("확인", role: .cancel) { }
            } message: {
                Text("중재 제안")
            }
            .sheet(isPresented: $showGoalDetails) {
                GoalDetailsView(configuration: session.configuration)
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
        GeometryReader { geometry in
            Button(action: action) {
                VStack(spacing: min(8, geometry.size.height * 0.08)) {
                    Text(name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)

                    Text(time)
                        .font(.system(size: min(36, geometry.size.width * 0.22), weight: .bold, design: .rounded))
                        .foregroundColor(color)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)

                    if isActive {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 6, height: 6)
                            Text("말하는 중")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .minimumScaleFactor(0.8)
                                .lineLimit(1)
                        }
                    } else {
                        Text("탭하여 시작")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .opacity(blinkOpacity)
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)
                            .onAppear {
                                withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                                    blinkOpacity = 0.3
                                }
                            }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, min(16, geometry.size.height * 0.12))
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
        .frame(minHeight: 120)
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
                        personName: session.speakerName(for: .personA),
                        personTime: session.personATime,
                        color: .blue
                    )
                    .frame(height: geometry.size.height / 2)
                    .rotationEffect(.degrees(180))

                    // 사람 B 영역 (정상 방향 - 아랫쪽에서 보는 사람용)
                    SinglePersonTimerView(
                        session: session,
                        person: .personB,
                        personName: session.speakerName(for: .personB),
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
                // 상단 여백 (safe area 고려)
                Spacer()
                    .frame(height: max(geometry.safeAreaInsets.top + 20, 40))

                Spacer()

                // 타이머 표시
                VStack(spacing: 10) {
                    Text(personName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)

                    Text(session.timeString(from: personTime))
                        .font(.system(size: min(60, geometry.size.width * 0.15), weight: .bold, design: .rounded))
                        .foregroundColor(color)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)

                    if isActive {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 12, height: 12)
                            Text("말하는 중")
                                .font(.headline)
                                .minimumScaleFactor(0.8)
                                .lineLimit(1)
                        }
                    }
                }
                .padding(.horizontal)

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
                            .minimumScaleFactor(0.7)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
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
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                }
                .padding(.bottom, 20)
                .padding(.horizontal)

                // 하단 여백 (safe area 고려)
                Spacer()
                    .frame(height: max(geometry.safeAreaInsets.bottom + 20, 40))
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

// MARK: - GoalDetailsView

struct GoalDetailsView: View {
    @Environment(\.dismiss) var dismiss
    let configuration: SessionConfiguration

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 대화 목표
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "target")
                                .font(.title2)
                                .foregroundColor(.blue)
                            Text("대화 목표")
                                .font(.title2)
                                .fontWeight(.bold)
                        }

                        Text(configuration.topic)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue.opacity(0.1))
                            )
                    }

                    Divider()

                    // 참여자
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "person.2")
                                .font(.title3)
                                .foregroundColor(.green)
                            Text("참여자")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }

                        HStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("첫 번째 참여자")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(configuration.personAName)
                                    .font(.body)
                                    .fontWeight(.medium)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("두 번째 참여자")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(configuration.personBName)
                                    .font(.body)
                                    .fontWeight(.medium)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.green.opacity(0.1))
                        )
                    }

                    Divider()

                    // 목표 시간
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "clock")
                                .font(.title3)
                                .foregroundColor(.orange)
                            Text("목표 시간")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }

                        Text("\(Int(configuration.targetDuration / 60))분")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.orange.opacity(0.1))
                            )
                    }

                    // 기대 결과
                    if !configuration.expectedOutcome.isEmpty {
                        Divider()

                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "star")
                                    .font(.title3)
                                    .foregroundColor(.purple)
                                Text("기대 결과")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }

                            Text(configuration.expectedOutcome)
                                .font(.body)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.purple.opacity(0.1))
                                )
                        }
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("대화 목표 확인")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
        }
    }
}
