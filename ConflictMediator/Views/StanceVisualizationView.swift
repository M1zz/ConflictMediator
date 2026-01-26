import SwiftUI

struct StanceVisualizationView: View {
    @ObservedObject var session: SessionModel
    @State private var showAddStance = false
    @State private var showEditStance = false
    @State private var editingStance: StancePosition?
    @State private var newTopic = ""
    @State private var personAStance: Double = 0.5
    @State private var personBStance: Double = 0.5
    @State private var showDeleteConfirmation = false
    @State private var stanceToDelete: StancePosition?

    var body: some View {
        NavigationView {
            VStack {
                if session.stancePositions.isEmpty {
                    GeometryReader { geometry in
                        VStack(spacing: min(20, geometry.size.height * 0.05)) {
                            Image(systemName: "chart.bar.xaxis")
                                .font(.system(size: min(60, geometry.size.width * 0.15)))
                                .foregroundColor(.gray)

                            Text("아직 입장 차이가 기록되지 않았습니다")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .minimumScaleFactor(0.8)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)

                            Text("아래 버튼을 눌러 새로운 주제에 대한 입장을 추가하세요")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .minimumScaleFactor(0.8)
                                .lineLimit(3)
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            ForEach(session.stancePositions) { stance in
                                StanceCard(
                                    stance: stance,
                                    onEdit: {
                                        editingStance = stance
                                        newTopic = stance.topic
                                        personAStance = stance.personA
                                        personBStance = stance.personB
                                        showEditStance = true
                                    },
                                    onDelete: {
                                        stanceToDelete = stance
                                        showDeleteConfirmation = true
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("입장 차이")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showAddStance = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showAddStance) {
                AddStanceView(
                    topic: $newTopic,
                    personAStance: $personAStance,
                    personBStance: $personBStance,
                    onSave: {
                        session.addStancePosition(
                            topic: newTopic,
                            personA: personAStance,
                            personB: personBStance
                        )
                        newTopic = ""
                        personAStance = 0.5
                        personBStance = 0.5
                        showAddStance = false
                    }
                )
            }
            .sheet(isPresented: $showEditStance) {
                if let editingStance = editingStance {
                    EditStanceView(
                        topic: $newTopic,
                        personAStance: $personAStance,
                        personBStance: $personBStance,
                        onSave: {
                            session.updateStancePosition(
                                editingStance,
                                topic: newTopic,
                                personA: personAStance,
                                personB: personBStance
                            )
                            newTopic = ""
                            personAStance = 0.5
                            personBStance = 0.5
                            self.editingStance = nil
                            showEditStance = false
                        }
                    )
                }
            }
            .alert("입장 차이 삭제", isPresented: $showDeleteConfirmation) {
                Button("취소", role: .cancel) {
                    stanceToDelete = nil
                }
                Button("삭제", role: .destructive) {
                    if let stance = stanceToDelete {
                        session.deleteStancePosition(stance)
                        stanceToDelete = nil
                    }
                }
            } message: {
                Text("이 입장 차이를 삭제하시겠습니까?")
            }
        }
    }
}

struct StanceCard: View {
    let stance: StancePosition
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        GeometryReader { outerGeometry in
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Text(stance.topic)
                        .font(.headline)
                        .minimumScaleFactor(0.8)
                        .lineLimit(2)

                    Spacer()

                    Button(action: onEdit) {
                        Image(systemName: "pencil.circle.fill")
                            .foregroundColor(.blue)
                            .imageScale(.large)
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: onDelete) {
                        Image(systemName: "trash.circle.fill")
                            .foregroundColor(.red)
                            .imageScale(.large)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                VStack(spacing: 8) {
                    HStack {
                        Text("사람 A")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .frame(width: max(50, outerGeometry.size.width * 0.15), alignment: .leading)
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 8)
                                    .clipShape(Capsule())

                                Rectangle()
                                    .fill(Color.blue)
                                    .frame(width: geometry.size.width * stance.personA, height: 8)
                                    .clipShape(Capsule())

                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 20, height: 20)
                                    .offset(x: geometry.size.width * stance.personA - 10)
                            }
                        }
                        .frame(height: 20)

                        Text("\(Int(stance.personA * 100))%")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .frame(width: max(35, outerGeometry.size.width * 0.12), alignment: .trailing)
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)
                    }

                    HStack {
                        Text("사람 B")
                            .font(.subheadline)
                            .foregroundColor(.green)
                            .frame(width: max(50, outerGeometry.size.width * 0.15), alignment: .leading)
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 8)
                                    .clipShape(Capsule())

                                Rectangle()
                                    .fill(Color.green)
                                    .frame(width: geometry.size.width * stance.personB, height: 8)
                                    .clipShape(Capsule())

                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 20, height: 20)
                                    .offset(x: geometry.size.width * stance.personB - 10)
                            }
                        }
                        .frame(height: 20)

                        Text("\(Int(stance.personB * 100))%")
                            .font(.caption)
                            .foregroundColor(.green)
                            .frame(width: max(35, outerGeometry.size.width * 0.12), alignment: .trailing)
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)
                    }
                }

                HStack {
                    Image(systemName: "arrow.left.and.right")
                        .foregroundColor(.orange)
                    Text("입장 차이: \(Int(abs(stance.personA - stance.personB) * 100))%")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                }
                .padding(.top, 5)

                HStack {
                    Text("전혀 동의 안함")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                    Spacer()
                    Text("완전 동의함")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                }
                .padding(.horizontal, max(40, outerGeometry.size.width * 0.12))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 5)
            )
        }
        .frame(minHeight: 180)
    }
}

struct AddStanceView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var topic: String
    @Binding var personAStance: Double
    @Binding var personBStance: Double
    let onSave: () -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("💡 논점 정하기 팁")) {
                    VStack(alignment: .leading, spacing: 8) {
                        TipRow(icon: "1.circle.fill", text: "구체적이고 명확한 주제를 정하세요", example: "예: \"이번 주말 계획\"")
                        TipRow(icon: "2.circle.fill", text: "한 문장으로 요약할 수 있어야 합니다", example: "예: \"반려동물 키우기\"")
                        TipRow(icon: "3.circle.fill", text: "양측의 입장이 명확히 다른 주제", example: "예: \"집 구매 vs 전세\"")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                Section(header: Text("주제")) {
                    TextField("예: 여행 계획", text: $topic)
                }

                Section(header: Text("사람 A의 입장")) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("전혀 동의 안함")
                                .font(.caption)
                            Spacer()
                            Text("완전 동의함")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)

                        Slider(value: $personAStance, in: 0...1)
                            .accentColor(.blue)

                        Text("동의 수준: \(Int(personAStance * 100))%")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }

                Section(header: Text("사람 B의 입장")) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("전혀 동의 안함")
                                .font(.caption)
                            Spacer()
                            Text("완전 동의함")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)

                        Slider(value: $personBStance, in: 0...1)
                            .accentColor(.green)

                        Text("동의 수준: \(Int(personBStance * 100))%")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                }

                Section {
                    HStack {
                        Image(systemName: "arrow.left.and.right")
                            .foregroundColor(.orange)
                        Text("입장 차이: \(Int(abs(personAStance - personBStance) * 100))%")
                            .foregroundColor(.orange)
                    }
                }
            }
            .navigationTitle("입장 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("저장") {
                        onSave()
                    }
                    .disabled(topic.isEmpty)
                }
            }
        }
    }
}

struct EditStanceView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var topic: String
    @Binding var personAStance: Double
    @Binding var personBStance: Double
    let onSave: () -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("주제")) {
                    TextField("예: 여행 계획", text: $topic)
                }

                Section(header: Text("사람 A의 입장")) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("전혀 동의 안함")
                                .font(.caption)
                            Spacer()
                            Text("완전 동의함")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)

                        Slider(value: $personAStance, in: 0...1)
                            .accentColor(.blue)

                        Text("동의 수준: \(Int(personAStance * 100))%")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }

                Section(header: Text("사람 B의 입장")) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("전혀 동의 안함")
                                .font(.caption)
                            Spacer()
                            Text("완전 동의함")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)

                        Slider(value: $personBStance, in: 0...1)
                            .accentColor(.green)

                        Text("동의 수준: \(Int(personBStance * 100))%")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                }

                Section {
                    HStack {
                        Image(systemName: "arrow.left.and.right")
                            .foregroundColor(.orange)
                        Text("입장 차이: \(Int(abs(personAStance - personBStance) * 100))%")
                            .foregroundColor(.orange)
                    }
                }
            }
            .navigationTitle("입장 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("저장") {
                        onSave()
                    }
                    .disabled(topic.isEmpty)
                }
            }
        }
    }
}

struct TipRow: View {
    let icon: String
    let text: String
    let example: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.caption)
            VStack(alignment: .leading, spacing: 2) {
                Text(text)
                    .fontWeight(.medium)
                Text(example)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    StanceVisualizationView(session: SessionModel())
}
