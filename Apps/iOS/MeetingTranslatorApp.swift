import SwiftUI

@main
struct MeetingTranslatorApp: App {
    @StateObject private var store = AppStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView(store: store)
                .onAppear { store.companion.activate() }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .background { store.enteredBackground() }
                }
        }
    }
}

struct RootView: View {
    @ObservedObject var store: AppStore

    var body: some View {
        TabView(selection: $store.selectedTab) {
            TextTranslationView(store: store)
                .tabItem { Label("텍스트", systemImage: "character.bubble") }
                .tag(AppStore.Tab.text)
            PlannedFeatureView(title: "대화 번역", icon: "waveform",
                               detail: "말을 듣고 번역문과 음성을 제공하는 기능을 준비 중입니다.",
                               features: ["한국어와 영어 양방향 대화", "원문과 번역문 함께 표시", "번역문 음성으로 듣기"])
                .tabItem { Label("대화", systemImage: "mic") }
                .tag(AppStore.Tab.conversation)
            PlannedFeatureView(title: "회의 기록·통역", icon: "person.3",
                               detail: "회의 녹음, 자막 번역, 회의록 작성 기능을 준비 중입니다.",
                               features: ["시간이 표시된 회의 기록", "요약·결정 사항·할 일", "회의장 자막과 통역", "Watch에서 중요한 순간 표시"])
                .tabItem { Label("회의", systemImage: "person.3") }
                .tag(AppStore.Tab.meeting)
            SettingsView(store: store, companion: store.companion)
                .tabItem { Label("설정", systemImage: "gearshape") }
                .tag(AppStore.Tab.settings)
        }
    }
}

struct PlannedFeatureView: View {
    let title: String
    let icon: String
    let detail: String
    let features: [String]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label("준비 중", systemImage: icon).font(.headline)
                    Text(detail)
                }
                Section("추가할 기능") {
                    ForEach(features, id: \.self) { Text($0) }
                }
            }
            .navigationTitle(title)
        }
    }
}
