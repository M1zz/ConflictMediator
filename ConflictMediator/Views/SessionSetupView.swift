import SwiftUI

struct SessionSetupView: View {
    @Binding var isPresented: Bool
    @Binding var configuration: SessionConfiguration
    @State private var showValidationError = false

    let onStart: () -> Void

    private let durationOptions = [15, 30, 45, 60, 90, 120]

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                Form {
                    Section(header: Text("대화 주제/목표 *")) {
                        TextEditor(text: $configuration.topic)
                            .frame(minHeight: min(80, geometry.size.height * 0.12))
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
                        TextField("두 번째 참여자 이름", text: $configuration.personBName)
                            .minimumScaleFactor(0.8)
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
                                Text("세션 시작")
                                    .fontWeight(.bold)
                                Spacer()
                            }
                        }
                        .disabled(configuration.topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .navigationTitle("세션 설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        isPresented = false
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

#Preview {
    SessionSetupView(
        isPresented: .constant(true),
        configuration: .constant(SessionConfiguration()),
        onStart: {}
    )
}
