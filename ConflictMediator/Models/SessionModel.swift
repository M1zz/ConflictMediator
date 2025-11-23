import Foundation
import SwiftUI

enum Speaker: String, Codable {
    case personA = "사람 A"
    case personB = "사람 B"
    case none = "없음"
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

class SessionModel: ObservableObject {
    @Published var currentSpeaker: Speaker = .none
    @Published var personATime: TimeInterval = 0
    @Published var personBTime: TimeInterval = 0
    @Published var isActive: Bool = false
    @Published var agreements: [Agreement] = []
    @Published var stancePositions: [StancePosition] = []
    @Published var showMediationPrompt: Bool = false
    @Published var currentPrompt: String = ""
    
    private var timer: Timer?
    private let turnTimeLimit: TimeInterval = 120
    
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
    
    func timeBalancePercentage() -> Double {
        let total = personATime + personBTime
        guard total > 0 else { return 0.5 }
        return personATime / total
    }
}
