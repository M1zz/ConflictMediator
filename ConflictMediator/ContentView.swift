import SwiftUI

struct ContentView: View {
    @StateObject private var session = SessionModel()
    
    var body: some View {
        TabView {
            TimerView(session: session)
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
        }
        .accentColor(.blue)
    }
}

#Preview {
    ContentView()
}
