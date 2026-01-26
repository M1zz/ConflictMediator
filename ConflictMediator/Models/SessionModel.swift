import Foundation
import SwiftUI
import AVFoundation

// MARK: - AudioRecorderManager

class AudioRecorderManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var permissionGranted = false
    @Published var recordingURL: URL?

    private var audioRecorder: AVAudioRecorder?
    private let recordingsDirectory: URL

    override init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        recordingsDirectory = documentsPath.appendingPathComponent("Recordings", isDirectory: true)

        super.init()

        try? FileManager.default.createDirectory(at: recordingsDirectory, withIntermediateDirectories: true)
    }

    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    self.permissionGranted = granted
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    func startRecording() -> Bool {
        guard permissionGranted else { return false }

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("오디오 세션 설정 실패: \(error)")
            return false
        }

        let fileName = generateFileName()
        recordingURL = recordingsDirectory.appendingPathComponent(fileName)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: recordingURL!, settings: settings)
            audioRecorder?.record()
            isRecording = true
            return true
        } catch {
            print("녹음 시작 실패: \(error)")
            return false
        }
    }

    func stopRecording() -> URL? {
        guard isRecording, let recorder = audioRecorder else { return nil }

        recorder.stop()
        isRecording = false

        try? AVAudioSession.sharedInstance().setActive(false)

        return recordingURL
    }

    private func generateFileName() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let dateString = dateFormatter.string(from: Date())
        return "\(dateString)_대화녹음.m4a"
    }

    func getRecordings() -> [URL] {
        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: recordingsDirectory,
                includingPropertiesForKeys: [.creationDateKey],
                options: .skipsHiddenFiles
            )
            return files.filter { $0.pathExtension == "m4a" }
                .sorted { (url1, url2) -> Bool in
                    let date1 = try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate
                    let date2 = try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate
                    return date1 ?? Date.distantPast > date2 ?? Date.distantPast
                }
        } catch {
            print("녹음 파일 목록 가져오기 실패: \(error)")
            return []
        }
    }
}

// MARK: - SessionConfiguration

struct SessionConfiguration: Codable {
    var topic: String
    var targetDuration: TimeInterval
    var personAName: String
    var personBName: String
    var expectedOutcome: String
    var createdAt: Date

    init(
        topic: String = "",
        targetDuration: TimeInterval = 1800,
        personAName: String = "사람 A",
        personBName: String = "사람 B",
        expectedOutcome: String = ""
    ) {
        self.topic = topic
        self.targetDuration = targetDuration
        self.personAName = personAName
        self.personBName = personBName
        self.expectedOutcome = expectedOutcome
        self.createdAt = Date()
    }
}

enum Speaker: String, Codable {
    case personA = "사람 A"
    case personB = "사람 B"
    case none = "없음"
}

enum EmotionalState: String, Codable {
    case hurt = "상함"
    case neutral = "보통"
    case good = "좋음"
    case resolved = "해소됨"
}

struct Agreement: Identifiable, Codable {
    let id: UUID
    var content: String
    var timestamp: Date
    var confirmedByA: Bool
    var confirmedByB: Bool
    var stancePositionId: UUID?

    init(content: String, stancePositionId: UUID? = nil) {
        self.id = UUID()
        self.content = content
        self.timestamp = Date()
        self.confirmedByA = false
        self.confirmedByB = false
        self.stancePositionId = stancePositionId
    }
}

struct StancePosition: Identifiable, Codable {
    let id: UUID
    var personA: Double
    var personB: Double
    var topic: String

    init(id: UUID = UUID(), personA: Double, personB: Double, topic: String) {
        self.id = id
        self.personA = personA
        self.personB = personB
        self.topic = topic
    }
}

struct SessionHistory: Identifiable, Codable {
    let id: UUID
    var configuration: SessionConfiguration
    var personATime: TimeInterval
    var personBTime: TimeInterval
    var totalElapsedTime: TimeInterval
    var agreements: [Agreement]
    var stancePositions: [StancePosition]
    var recordingURL: URL?
    var endedAt: Date

    init(
        id: UUID = UUID(),
        configuration: SessionConfiguration,
        personATime: TimeInterval,
        personBTime: TimeInterval,
        totalElapsedTime: TimeInterval,
        agreements: [Agreement],
        stancePositions: [StancePosition],
        recordingURL: URL?,
        endedAt: Date = Date()
    ) {
        self.id = id
        self.configuration = configuration
        self.personATime = personATime
        self.personBTime = personBTime
        self.totalElapsedTime = totalElapsedTime
        self.agreements = agreements
        self.stancePositions = stancePositions
        self.recordingURL = recordingURL
        self.endedAt = endedAt
    }
}

class SessionHistoryManager: ObservableObject {
    @Published var histories: [SessionHistory] = []

    private let historyKey = "sessionHistories"

    init() {
        loadHistories()
    }

    func saveHistory(_ history: SessionHistory) {
        histories.insert(history, at: 0) // Insert at beginning (most recent first)
        saveHistories()
    }

    func deleteHistory(_ history: SessionHistory) {
        histories.removeAll { $0.id == history.id }
        saveHistories()
    }

    private func saveHistories() {
        if let encoded = try? JSONEncoder().encode(histories) {
            UserDefaults.standard.set(encoded, forKey: historyKey)
        }
    }

    private func loadHistories() {
        if let data = UserDefaults.standard.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([SessionHistory].self, from: data) {
            histories = decoded
        }
    }
}

class SessionModel: ObservableObject {
    @Published var currentSpeaker: Speaker = .none
    @Published var personATime: TimeInterval = 0
    @Published var personBTime: TimeInterval = 0
    @Published var isActive: Bool = false
    @Published var agreements: [Agreement] = []
    @Published var stancePositions: [StancePosition] = []
    @Published var showMediationPrompt: Bool = false
    @Published var currentPrompt: String = ""
    @Published var personAEmotion: EmotionalState = .neutral
    @Published var personBEmotion: EmotionalState = .neutral

    // 새로 추가된 속성들
    @Published var configuration: SessionConfiguration = SessionConfiguration()
    @Published var sessionStartTime: Date?
    @Published var totalElapsedTime: TimeInterval = 0
    @Published var showTimeUpAlert = false
    @Published var sessionTimeRemaining: TimeInterval = 0

    let audioRecorder = AudioRecorderManager()

    private var timer: Timer?
    private let turnTimeLimit: TimeInterval = 120

    var anyoneHurt: Bool {
        personAEmotion == .hurt || personBEmotion == .hurt
    }

    var emotionsResolved: Bool {
        (personAEmotion == .resolved || personAEmotion == .good || personAEmotion == .neutral) &&
        (personBEmotion == .resolved || personBEmotion == .good || personBEmotion == .neutral)
    }
    
    let mediationPrompts = [
        "상대방이 방금 한 말을 자신의 언어로 요약해보세요",
        "'당신은 틀렸어' 대신 '나는 이렇게 느꼈어'로 표현해보세요",
        "이 문제가 해결되면 어떤 모습일지 구체적으로 말해보세요",
        "상대방의 감정을 인정하는 말로 시작해보세요",
        "비난 대신 나의 필요를 표현해보세요",
        "이 상황에서 우리가 동의하는 부분은 무엇인가요?",
        "10점 만점에 지금 감정의 강도는 몇 점인가요?",
        "잠시 멈추고 깊게 숨을 쉬어볼까요?"
    ]
    
    func startSession() {
        isActive = true

        if sessionStartTime == nil {
            sessionStartTime = Date()
            sessionTimeRemaining = configuration.targetDuration
        }

        if audioRecorder.permissionGranted {
            let recordingStarted = audioRecorder.startRecording()
            if !recordingStarted {
                print("녹음 시작 실패")
            }
        }

        startTimer()
    }

    func pauseSession() {
        isActive = false
        stopTimer()
    }

    func resetSession() {
        isActive = false
        stopTimer()
        personATime = 0
        personBTime = 0
        currentSpeaker = .none
        agreements.removeAll()
        stancePositions.removeAll()

        sessionStartTime = nil
        totalElapsedTime = 0
        sessionTimeRemaining = configuration.targetDuration

        if audioRecorder.isRecording {
            _ = audioRecorder.stopRecording()
        }
    }

    func endSession() {
        pauseSession()

        if let recordingURL = audioRecorder.stopRecording() {
            print("녹음 저장됨: \(recordingURL)")
        }
    }

    func createSessionHistory() -> SessionHistory {
        return SessionHistory(
            configuration: configuration,
            personATime: personATime,
            personBTime: personBTime,
            totalElapsedTime: totalElapsedTime,
            agreements: agreements,
            stancePositions: stancePositions,
            recordingURL: audioRecorder.recordingURL
        )
    }
    
    func switchSpeaker(to speaker: Speaker) {
        currentSpeaker = speaker
        if !isActive {
            startSession()
        }
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, self.isActive else { return }

            if let startTime = self.sessionStartTime {
                self.totalElapsedTime = Date().timeIntervalSince(startTime)
                self.sessionTimeRemaining = max(0, self.configuration.targetDuration - self.totalElapsedTime)

                if self.totalElapsedTime >= self.configuration.targetDuration && !self.showTimeUpAlert {
                    self.showTimeUpAlert = true
                    self.pauseSession()
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            }

            switch self.currentSpeaker {
            case .personA:
                self.personATime += 1
                if self.personATime.truncatingRemainder(dividingBy: self.turnTimeLimit) == 0 {
                    self.suggestTurnSwitch()
                }
            case .personB:
                self.personBTime += 1
                if self.personBTime.truncatingRemainder(dividingBy: self.turnTimeLimit) == 0 {
                    self.suggestTurnSwitch()
                }
            case .none:
                break
            }

            let timeDifference = abs(self.personATime - self.personBTime)
            if timeDifference > 180 && Int(timeDifference) % 60 == 0 {
                self.showRandomMediationPrompt()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func suggestTurnSwitch() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
        showRandomMediationPrompt()
    }
    
    func showRandomMediationPrompt() {
        if let prompt = mediationPrompts.randomElement() {
            currentPrompt = prompt
            showMediationPrompt = true
        }
    }
    
    func addAgreement(_ content: String, stancePositionId: UUID? = nil) {
        let agreement = Agreement(content: content, stancePositionId: stancePositionId)
        agreements.append(agreement)
    }

    func getStancePosition(byId id: UUID) -> StancePosition? {
        return stancePositions.first { $0.id == id }
    }
    
    func confirmAgreement(_ agreement: Agreement, by speaker: Speaker) {
        if let index = agreements.firstIndex(where: { $0.id == agreement.id }) {
            switch speaker {
            case .personA:
                agreements[index].confirmedByA = true
            case .personB:
                agreements[index].confirmedByB = true
            case .none:
                break
            }
        }
    }
    
    func addStancePosition(topic: String, personA: Double, personB: Double) {
        let stance = StancePosition(personA: personA, personB: personB, topic: topic)
        stancePositions.append(stance)
    }

    func updateStancePosition(_ stance: StancePosition, topic: String, personA: Double, personB: Double) {
        if let index = stancePositions.firstIndex(where: { $0.id == stance.id }) {
            stancePositions[index].topic = topic
            stancePositions[index].personA = personA
            stancePositions[index].personB = personB
        }
    }

    func deleteStancePosition(_ stance: StancePosition) {
        stancePositions.removeAll { $0.id == stance.id }
    }
    
    func timeString(from interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    func sessionTimeRemainingString() -> String {
        let minutes = Int(sessionTimeRemaining) / 60
        let seconds = Int(sessionTimeRemaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    func speakerName(for speaker: Speaker) -> String {
        switch speaker {
        case .personA:
            return configuration.personAName
        case .personB:
            return configuration.personBName
        case .none:
            return "없음"
        }
    }

    func timeBalancePercentage() -> Double {
        let total = personATime + personBTime
        guard total > 0 else { return 0.5 }
        return personATime / total
    }
}
