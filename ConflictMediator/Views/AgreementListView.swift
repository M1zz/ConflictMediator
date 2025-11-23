import SwiftUI

struct AgreementListView: View {
    @ObservedObject var session: SessionModel
    @State private var showAddAgreement = false
    @State private var newAgreementText = ""
    @State private var selectedStanceId: UUID?

    var body: some View {
        NavigationView {
            VStack {
                if session.agreements.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("아직 합의된 사항이 없습니다")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("대화 중 합의한 내용을 기록하세요")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(session.agreements) { agreement in
                            AgreementRow(
                                agreement: agreement,
                                onConfirmByA: {
                                    session.confirmAgreement(agreement, by: .personA)
                                },
                                onConfirmByB: {
                                    session.confirmAgreement(agreement, by: .personB)
                                },
                                session: session
                            )
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("합의 사항")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showAddAgreement = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showAddAgreement) {
                AddAgreementView(
                    session: session,
                    agreementText: $newAgreementText,
                    selectedStanceId: $selectedStanceId,
                    onSave: {
                        session.addAgreement(newAgreementText, stancePositionId: selectedStanceId)
                        newAgreementText = ""
                        selectedStanceId = nil
                        showAddAgreement = false
                    }
                )
            }
        }
    }
}

struct AgreementRow: View {
    let agreement: Agreement
    let onConfirmByA: () -> Void
    let onConfirmByB: () -> Void
    @ObservedObject var session: SessionModel

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }

    var relatedStance: StancePosition? {
        if let stanceId = agreement.stancePositionId {
            return session.getStancePosition(byId: stanceId)
        }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let stance = relatedStance {
                HStack(spacing: 5) {
                    Image(systemName: "tag.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Text(stance.topic)
                        .font(.caption)
                        .foregroundColor(.orange)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }

            Text(agreement.content)
                .font(.body)

            Text(dateFormatter.string(from: agreement.timestamp))
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 20) {
                Button(action: onConfirmByA) {
                    HStack(spacing: 5) {
                        Image(systemName: agreement.confirmedByA ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(agreement.confirmedByA ? .blue : .gray)
                        Text("사람 A 확인")
                            .font(.caption)
                            .foregroundColor(agreement.confirmedByA ? .blue : .secondary)
                    }
                }
                .disabled(agreement.confirmedByA)
                
                Button(action: onConfirmByB) {
                    HStack(spacing: 5) {
                        Image(systemName: agreement.confirmedByB ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(agreement.confirmedByB ? .green : .gray)
                        Text("사람 B 확인")
                            .font(.caption)
                            .foregroundColor(agreement.confirmedByB ? .green : .secondary)
                    }
                }
                .disabled(agreement.confirmedByB)
            }
            
            if agreement.confirmedByA && agreement.confirmedByB {
                HStack {
                    Image(systemName: "hand.thumbsup.fill")
                        .foregroundColor(.orange)
                    Text("양측 모두 확인 완료")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .fontWeight(.semibold)
                }
                .padding(.top, 5)
            }
        }
        .padding(.vertical, 8)
    }
}

struct AddAgreementView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var session: SessionModel
    @Binding var agreementText: String
    @Binding var selectedStanceId: UUID?
    let onSave: () -> Void

    var selectedStance: StancePosition? {
        if let id = selectedStanceId {
            return session.getStancePosition(byId: id)
        }
        return nil
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("관련 주제 선택 (선택사항)")) {
                    if session.stancePositions.isEmpty {
                        Text("등록된 입장 차이가 없습니다")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    } else {
                        Picker("주제", selection: $selectedStanceId) {
                            Text("일반 합의 (주제 없음)")
                                .tag(nil as UUID?)

                            ForEach(session.stancePositions) { stance in
                                HStack {
                                    Text(stance.topic)
                                    Spacer()
                                    Text("차이 \(Int(abs(stance.personA - stance.personB) * 100))%")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                                .tag(stance.id as UUID?)
                            }
                        }
                        .pickerStyle(.navigationLink)
                    }

                    if let stance = selectedStance {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("사람 A:")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                Text("\(Int(stance.personA * 100))% 동의")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            HStack {
                                Text("사람 B:")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                Text("\(Int(stance.personB * 100))% 동의")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section(header: Text("합의 내용")) {
                    TextEditor(text: $agreementText)
                        .frame(minHeight: 100)
                }

                Section {
                    Text("양측이 모두 확인해야 최종 합의로 간주됩니다")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("합의 추가")
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
                    .disabled(agreementText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    AgreementListView(session: SessionModel())
}
