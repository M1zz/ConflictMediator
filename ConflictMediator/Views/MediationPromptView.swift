import SwiftUI

struct MediationPromptView: View {
    @ObservedObject var session: SessionModel
    
    var body: some View {
        NavigationView {
            GeometryReader { outerGeometry in
                ScrollView {
                    VStack(spacing: 20) {
                        // 감정 체크 섹션
                        VStack(spacing: 15) {
                            HStack {
                                Image(systemName: "heart.text.square.fill")
                                    .font(.system(size: min(40, outerGeometry.size.width * 0.1)))
                                    .foregroundColor(.pink)
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("감정 상태 체크")
                                        .font(.headline)
                                        .minimumScaleFactor(0.8)
                                        .lineLimit(1)
                                    Text("대화 전 감정을 확인하세요")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .minimumScaleFactor(0.8)
                                        .lineLimit(1)
                                }
                                Spacer()
                            }
                            .padding()

                        EmotionCheckCard(
                            person: "사람 A",
                            emotion: $session.personAEmotion,
                            color: .blue
                        )

                        EmotionCheckCard(
                            person: "사람 B",
                            emotion: $session.personBEmotion,
                            color: .green
                        )

                        // 감정이 상했을 때 경고
                        if session.anyoneHurt {
                            EmotionHealingGuide()
                        } else if session.emotionsResolved {
                            VStack(spacing: 10) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("감정이 안정되었습니다")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                                Text("이제 입장 차이와 합의 사항을 논의할 준비가 되었습니다")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.green.opacity(0.1))
                            )
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top)

                        Divider()
                            .padding(.horizontal)

                        VStack(spacing: 10) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: min(50, outerGeometry.size.width * 0.12)))
                                .foregroundColor(.yellow)

                            Text("대화를 더 건설적으로 만들어보세요")
                                .font(.headline)
                                .multilineTextAlignment(.center)
                                .minimumScaleFactor(0.8)
                                .lineLimit(2)
                                .padding(.horizontal)

                            Text("아래 제안들을 참고하여 서로를 이해하고 갈등을 해결해보세요")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .minimumScaleFactor(0.8)
                                .lineLimit(3)
                        }

                        Divider()
                            .padding(.horizontal)
                    
                        VStack(spacing: 15) {
                            ForEach(session.mediationPrompts, id: \.self) { prompt in
                                PromptCard(prompt: prompt)
                            }
                        }
                        .padding(.horizontal)

                        VStack(alignment: .leading, spacing: 15) {
                            Text("대화 팁")
                                .font(.headline)
                                .padding(.horizontal)
                                .minimumScaleFactor(0.8)
                                .lineLimit(1)

                            TipCard(
                                icon: "ear",
                                title: "적극적 경청",
                                description: "상대방의 말을 끝까지 듣고, 이해한 내용을 확인하세요"
                            )

                            TipCard(
                                icon: "person.2",
                                title: "I-Message 사용",
                                description: "'당신이 ~했어'보다 '나는 ~라고 느꼈어'로 표현하세요"
                            )

                            TipCard(
                                icon: "clock",
                                title: "휴식 시간",
                                description: "감정이 격해지면 5-10분 휴식 후 다시 대화하세요"
                            )

                            TipCard(
                                icon: "target",
                                title: "문제 해결 집중",
                                description: "과거 비난보다 미래 해결책에 초점을 맞추세요"
                            )
                        }
                        .padding(.top)
                    }
                    .padding(.bottom, max(20, outerGeometry.safeAreaInsets.bottom + 20))
                }
            }
            .navigationTitle("중재 도움말")
        }
    }
}

struct PromptCard: View {
    let prompt: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "quote.opening")
                    .foregroundColor(.blue)
                    .font(.caption)

                Text(prompt)
                    .font(.body)
                    .foregroundColor(.primary)
                    .minimumScaleFactor(0.8)
                    .lineLimit(3)

                Spacer()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct TipCard: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.orange)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .minimumScaleFactor(0.8)
                    .lineLimit(2)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .minimumScaleFactor(0.8)
                    .lineLimit(3)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5)
        )
        .padding(.horizontal)
    }
}

struct EmotionCheckCard: View {
    let person: String
    @Binding var emotion: EmotionalState
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(person)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                Spacer()
            }

            HStack(spacing: 10) {
                EmotionButton(emotion: .good, currentEmotion: $emotion, icon: "face.smiling", label: "좋음", color: .green)
                EmotionButton(emotion: .neutral, currentEmotion: $emotion, icon: "face.dashed", label: "보통", color: .gray)
                EmotionButton(emotion: .hurt, currentEmotion: $emotion, icon: "face.frowning", label: "상함", color: .red)
                EmotionButton(emotion: .resolved, currentEmotion: $emotion, icon: "checkmark.circle", label: "해소", color: .blue)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5)
        )
        .padding(.horizontal)
    }
}

struct EmotionButton: View {
    let emotion: EmotionalState
    @Binding var currentEmotion: EmotionalState
    let icon: String
    let label: String
    let color: Color

    var isSelected: Bool {
        currentEmotion == emotion
    }

    var body: some View {
        Button(action: {
            currentEmotion = emotion
        }) {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.title2)
                Text(label)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? color.opacity(0.2) : Color(UIColor.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
            .foregroundColor(isSelected ? color : .secondary)
        }
    }
}

struct EmotionHealingGuide: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
                Text("감정이 상한 상태입니다")
                    .font(.headline)
                    .foregroundColor(.orange)
            }

            Text("합의나 논의 전에 먼저 감정을 해소하는 것이 중요합니다")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Text("감정 해소 단계")
                    .font(.headline)

                HealingStepCard(
                    number: "1",
                    title: "잠시 멈추기",
                    description: "5분 정도 각자 시간을 가지고 진정하세요",
                    color: .blue
                )

                HealingStepCard(
                    number: "2",
                    title: "감정 표현하기",
                    description: "\"나는 ~했을 때 ~라고 느꼈어\"로 감정을 표현하세요",
                    color: .purple
                )

                HealingStepCard(
                    number: "3",
                    title: "경청하기",
                    description: "상대방의 감정을 비난하지 않고 들어주세요",
                    color: .orange
                )

                HealingStepCard(
                    number: "4",
                    title: "사과와 화해",
                    description: "잘못한 부분이 있다면 진심으로 사과하세요",
                    color: .pink
                )

                HealingStepCard(
                    number: "5",
                    title: "감정 확인",
                    description: "감정이 해소되었다면 위에서 '해소'로 체크하세요",
                    color: .green
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 2)
                )
        )
        .padding(.horizontal)
    }
}

struct HealingStepCard: View {
    let number: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 30, height: 30)
                Text(number)
                    .font(.headline)
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    MediationPromptView(session: SessionModel())
}
