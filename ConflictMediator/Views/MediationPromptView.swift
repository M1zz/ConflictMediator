import SwiftUI

struct MediationPromptView: View {
    @ObservedObject var session: SessionModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 10) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.yellow)
                        
                        Text("대화를 더 건설적으로 만들어보세요")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                        
                        Text("아래 제안들을 참고하여 서로를 이해하고 갈등을 해결해보세요")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top)
                    
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
                .padding(.bottom)
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
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
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

#Preview {
    MediationPromptView(session: SessionModel())
}
