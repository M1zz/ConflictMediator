import SwiftUI
import AVFoundation

// MARK: - AudioPlayerManager

class AudioPlayerManager: NSObject, ObservableObject {
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0

    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?

    func loadAudio(url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            duration = audioPlayer?.duration ?? 0
            currentTime = 0
        } catch {
            print("오디오 로드 실패: \(error)")
        }
    }

    func play() {
        guard let player = audioPlayer else { return }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("오디오 세션 설정 실패: \(error)")
        }

        player.play()
        isPlaying = true
        startTimer()
    }

    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        stopTimer()
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        isPlaying = false
        currentTime = 0
        stopTimer()
    }

    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = time
        currentTime = time
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.audioPlayer else { return }
            self.currentTime = player.currentTime
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    deinit {
        stopTimer()
        audioPlayer?.stop()
    }
}

extension AudioPlayerManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        currentTime = 0
        stopTimer()
    }
}

// MARK: - Keyboard Helper

extension View {
    func hideKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

struct ContentView: View {
    @StateObject private var session = SessionModel()
    @StateObject private var historyManager = SessionHistoryManager()
    @State private var showSessionSetup = true
    @State private var sessionConfiguration = SessionConfiguration()

    var body: some View {
        TabView {
            TimerView(session: session, historyManager: historyManager)
                .tabItem {
                    Label("대화 타이머", systemImage: "timer")
                }

            StanceVisualizationView(session: session)
                .tabItem {
                    Label("입장 차이", systemImage: "chart.bar.xaxis")
                }

            AgreementListView(session: session)
                .tabItem {
                    Label("합의 사항", systemImage: "checkmark.circle")
                }

            MediationPromptView(session: session)
                .tabItem {
                    Label("중재 도움말", systemImage: "lightbulb")
                }

            HistoryListView(historyManager: historyManager)
                .tabItem {
                    Label("대화 기록", systemImage: "clock.arrow.circlepath")
                }
        }
        .accentColor(.blue)
        .sheet(isPresented: $showSessionSetup) {
            SessionSetupView(
                isPresented: $showSessionSetup,
                configuration: $sessionConfiguration,
                onStart: {
                    session.configuration = sessionConfiguration

                    Task {
                        let granted = await session.audioRecorder.requestPermission()
                        if !granted {
                            print("녹음 권한이 거부되었습니다")
                        }
                    }
                }
            )
        }
        .alert("목표 시간 도달", isPresented: $session.showTimeUpAlert) {
            Button("세션 종료") {
                // Save session to history before ending
                let history = session.createSessionHistory()
                historyManager.saveHistory(history)

                session.endSession()
                showSessionSetup = true
                sessionConfiguration = SessionConfiguration()
            }
            Button("계속하기") {
                session.startSession()
            }
        } message: {
            Text("설정한 목표 시간 \(Int(session.configuration.targetDuration / 60))분이 되었습니다.\n세션을 종료하거나 계속 진행할 수 있습니다.")
        }
    }
}

#Preview {
    ContentView()
}

// MARK: - SessionSetupView

struct SessionSetupView: View {
    @Binding var isPresented: Bool
    @Binding var configuration: SessionConfiguration
    @State private var showValidationError = false

    let onStart: () -> Void

    private let durationOptions = [15, 30, 45, 60, 90, 120]

    @FocusState private var focusedField: Field?

    enum Field {
        case topic, personA, personB, outcome
    }

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                Form {
                    Section(header: Text("대화 주제/목표 *")) {
                        TextEditor(text: $configuration.topic)
                            .frame(minHeight: min(80, geometry.size.height * 0.12))
                            .focused($focusedField, equals: .topic)
                            .overlay(
                                Group {
                                    if configuration.topic.isEmpty {
                                        Text("예: 휴가 계획 논의, 가사 분담 조정")
                                            .foregroundColor(.gray)
                                            .opacity(0.5)
                                            .padding(.leading, 4)
                                            .padding(.top, 8)
                                    }
                                },
                                alignment: .topLeading
                            )
                    }

                    Section(header: Text("참여자")) {
                        TextField("첫 번째 참여자 이름", text: $configuration.personAName)
                            .minimumScaleFactor(0.8)
                            .focused($focusedField, equals: .personA)
                        TextField("두 번째 참여자 이름", text: $configuration.personBName)
                            .minimumScaleFactor(0.8)
                            .focused($focusedField, equals: .personB)
                    }

                    Section(header: Text("목표 시간")) {
                        Picker("시간 설정", selection: $configuration.targetDuration) {
                            ForEach(durationOptions, id: \.self) { minutes in
                                Text("\(minutes)분").tag(TimeInterval(minutes * 60))
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    Section(header: Text("기대 결과 (선택사항)")) {
                        TextEditor(text: $configuration.expectedOutcome)
                            .frame(minHeight: min(80, geometry.size.height * 0.12))
                            .focused($focusedField, equals: .outcome)
                            .overlay(
                                Group {
                                    if configuration.expectedOutcome.isEmpty {
                                        Text("예: 구체적인 일정 합의, 서로의 입장 이해")
                                            .foregroundColor(.gray)
                                            .opacity(0.5)
                                            .padding(.leading, 4)
                                            .padding(.top, 8)
                                    }
                                },
                                alignment: .topLeading
                            )
                    }

                    Section {
                        Button(action: startSession) {
                            HStack {
                                Spacer()
                                Image(systemName: "play.fill")
                                Text("목표를 정하고 대화 시작")
                                    .fontWeight(.bold)
                                Spacer()
                            }
                        }
                        .disabled(configuration.topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }

                    Section {
                        Text("대화 중에도 언제든지 목표를 다시 확인할 수 있습니다")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("대화의 목표 정하기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        isPresented = false
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("완료") {
                        focusedField = nil
                    }
                }
            }
            .alert("주제를 입력해주세요", isPresented: $showValidationError) {
                Button("확인", role: .cancel) { }
            } message: {
                Text("대화 주제/목표는 필수 항목입니다.")
            }
        }
    }

    private func startSession() {
        let trimmedTopic = configuration.topic.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTopic.isEmpty else {
            showValidationError = true
            return
        }

        isPresented = false
        onStart()
    }
}

// MARK: - HistoryListView

struct HistoryListView: View {
    @ObservedObject var historyManager: SessionHistoryManager
    @State private var selectedHistory: SessionHistory?

    var body: some View {
        NavigationView {
            Group {
                if historyManager.histories.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("아직 종료된 대화가 없습니다")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    List {
                        ForEach(historyManager.histories) { history in
                            Button(action: {
                                selectedHistory = history
                            }) {
                                HistoryRowView(history: history)
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                historyManager.deleteHistory(historyManager.histories[index])
                            }
                        }
                    }
                }
            }
            .navigationTitle("대화 기록")
            .toolbar {
                EditButton()
            }
            .sheet(item: $selectedHistory) { history in
                HistoryDetailView(history: history)
            }
        }
    }
}

struct HistoryRowView: View {
    let history: SessionHistory

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(history.configuration.topic)
                .font(.headline)
                .lineLimit(2)

            HStack {
                Label("\(Int(history.totalElapsedTime / 60))분", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(history.endedAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                    Text("\(history.configuration.personAName): \(Int(history.personATime / 60))분")
                        .font(.caption2)
                }

                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("\(history.configuration.personBName): \(Int(history.personBTime / 60))분")
                        .font(.caption2)
                }

                if history.recordingURL != nil {
                    Image(systemName: "mic.fill")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }

            if !history.agreements.isEmpty {
                Text("합의 사항: \(history.agreements.count)개")
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

struct HistoryDetailView: View {
    @Environment(\.dismiss) var dismiss
    let history: SessionHistory
    @StateObject private var audioPlayer = AudioPlayerManager()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 대화 목표
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "target")
                                .foregroundColor(.blue)
                            Text("대화 목표")
                                .font(.headline)
                        }
                        Text(history.configuration.topic)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue.opacity(0.1))
                            )
                    }

                    Divider()

                    // 시간 정보
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.orange)
                            Text("시간 정보")
                                .font(.headline)
                        }

                        VStack(spacing: 8) {
                            HStack {
                                Text("총 대화 시간")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(Int(history.totalElapsedTime / 60))분 \(Int(history.totalElapsedTime.truncatingRemainder(dividingBy: 60)))초")
                                    .fontWeight(.semibold)
                            }

                            HStack {
                                Text("\(history.configuration.personAName)")
                                    .foregroundColor(.blue)
                                Spacer()
                                Text("\(Int(history.personATime / 60))분 \(Int(history.personATime.truncatingRemainder(dividingBy: 60)))초")
                                    .fontWeight(.semibold)
                            }

                            HStack {
                                Text("\(history.configuration.personBName)")
                                    .foregroundColor(.green)
                                Spacer()
                                Text("\(Int(history.personBTime / 60))분 \(Int(history.personBTime.truncatingRemainder(dividingBy: 60)))초")
                                    .fontWeight(.semibold)
                            }

                            HStack {
                                Text("종료 일시")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(history.endedAt, style: .date)
                                    .fontWeight(.semibold)
                                Text(history.endedAt, style: .time)
                                    .fontWeight(.semibold)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.orange.opacity(0.1))
                        )
                    }

                    // 합의 사항
                    if !history.agreements.isEmpty {
                        Divider()

                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "checkmark.circle")
                                    .foregroundColor(.green)
                                Text("합의 사항 (\(history.agreements.count))")
                                    .font(.headline)
                            }

                            VStack(spacing: 8) {
                                ForEach(Array(history.agreements.enumerated()), id: \.element.id) { index, agreement in
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("\(index + 1).")
                                            .foregroundColor(.secondary)
                                        Text(agreement.content)
                                        Spacer()
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.green.opacity(0.1))
                                    )
                                }
                            }
                        }
                    }

                    // 입장 차이
                    if !history.stancePositions.isEmpty {
                        Divider()

                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "chart.bar")
                                    .foregroundColor(.purple)
                                Text("입장 차이 (\(history.stancePositions.count))")
                                    .font(.headline)
                            }

                            VStack(spacing: 12) {
                                ForEach(history.stancePositions) { stance in
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(stance.topic)
                                            .font(.subheadline)
                                            .fontWeight(.medium)

                                        HStack {
                                            Text(history.configuration.personAName)
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                            Spacer()
                                            Text(history.configuration.personBName)
                                                .font(.caption)
                                                .foregroundColor(.green)
                                        }

                                        GeometryReader { geometry in
                                            ZStack(alignment: .leading) {
                                                Rectangle()
                                                    .fill(Color.gray.opacity(0.2))
                                                    .frame(height: 8)

                                                HStack(spacing: 0) {
                                                    Circle()
                                                        .fill(Color.blue)
                                                        .frame(width: 16, height: 16)
                                                        .offset(x: CGFloat(stance.personA) * (geometry.size.width - 16))

                                                    Spacer()

                                                    Circle()
                                                        .fill(Color.green)
                                                        .frame(width: 16, height: 16)
                                                        .offset(x: -((1 - CGFloat(stance.personB)) * (geometry.size.width - 16)))
                                                }
                                            }
                                        }
                                        .frame(height: 16)
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.purple.opacity(0.1))
                                    )
                                }
                            }
                        }
                    }

                    // 녹음 파일
                    if let recordingURL = history.recordingURL {
                        Divider()

                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "mic.fill")
                                    .foregroundColor(.red)
                                Text("녹음 파일")
                                    .font(.headline)
                                Spacer()
                                ShareLink(item: recordingURL) {
                                    Label("공유", systemImage: "square.and.arrow.up")
                                        .font(.subheadline)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                            }

                            VStack(spacing: 12) {
                                // 파일 정보
                                HStack {
                                    Image(systemName: "waveform")
                                        .foregroundColor(.red)
                                    Text(recordingURL.lastPathComponent)
                                        .font(.caption)
                                        .lineLimit(1)
                                    Spacer()
                                }

                                // 재생 컨트롤
                                VStack(spacing: 8) {
                                    // 진행 바
                                    GeometryReader { geometry in
                                        ZStack(alignment: .leading) {
                                            Rectangle()
                                                .fill(Color.gray.opacity(0.3))
                                                .frame(height: 4)
                                                .cornerRadius(2)

                                            Rectangle()
                                                .fill(Color.red)
                                                .frame(width: audioPlayer.duration > 0 ? geometry.size.width * CGFloat(audioPlayer.currentTime / audioPlayer.duration) : 0, height: 4)
                                                .cornerRadius(2)
                                        }
                                        .gesture(
                                            DragGesture(minimumDistance: 0)
                                                .onChanged { value in
                                                    let newTime = Double(value.location.x / geometry.size.width) * audioPlayer.duration
                                                    audioPlayer.seek(to: newTime)
                                                }
                                        )
                                    }
                                    .frame(height: 4)

                                    // 시간 표시
                                    HStack {
                                        Text(formatTime(audioPlayer.currentTime))
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text(formatTime(audioPlayer.duration))
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }

                                    // 재생 버튼
                                    HStack(spacing: 20) {
                                        Button(action: {
                                            audioPlayer.seek(to: max(0, audioPlayer.currentTime - 10))
                                        }) {
                                            Image(systemName: "gobackward.10")
                                                .font(.title2)
                                                .foregroundColor(.red)
                                        }

                                        Button(action: {
                                            if audioPlayer.isPlaying {
                                                audioPlayer.pause()
                                            } else {
                                                audioPlayer.play()
                                            }
                                        }) {
                                            Image(systemName: audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                                .font(.system(size: 50))
                                                .foregroundColor(.red)
                                        }

                                        Button(action: {
                                            audioPlayer.seek(to: min(audioPlayer.duration, audioPlayer.currentTime + 10))
                                        }) {
                                            Image(systemName: "goforward.10")
                                                .font(.title2)
                                                .foregroundColor(.red)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.red.opacity(0.1))
                            )
                        }
                        .onAppear {
                            audioPlayer.loadAudio(url: recordingURL)
                        }
                        .onDisappear {
                            audioPlayer.stop()
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("대화 상세")
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

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
