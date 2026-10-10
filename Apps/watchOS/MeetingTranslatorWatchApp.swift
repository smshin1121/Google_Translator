import SwiftUI
import WatchKit
import TranslatorCore

@main
struct MeetingTranslatorWatchApp: App {
    @StateObject private var companion = CompanionLink()
    var body: some Scene {
        WindowGroup {
            WatchTranslationView(companion: companion)
                .onAppear { companion.activate() }
        }
    }
}

struct WatchTranslationView: View {
    @ObservedObject var companion: CompanionLink
    @State private var input = ""
    @State private var source: AppLanguage = .korean

    private var target: AppLanguage { source == .korean ? .english : .korean }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(companion.connectionText).font(.caption).foregroundStyle(.secondary)
                    Picker("번역 방향", selection: $source) {
                        Text("한국어 → 영어").tag(AppLanguage.korean)
                        Text("영어 → 한국어").tag(AppLanguage.english)
                    }
                    .disabled(companion.waiting)
                    TextField("짧은 문장 입력", text: $input)
                        .disabled(companion.waiting)
                    Button {
                        let request = TranslationRequest(text: input, source: source, target: target)
                        companion.send(WatchRequest(translation: request))
                    } label: {
                        Label(companion.waiting ? "번역 기다리는 중" : "iPhone에서 번역",
                              systemImage: "character.bubble")
                    }
                    .disabled(companion.waiting || input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    if let response = companion.response {
                        if response.status == .completed { Text("번역 결과").font(.headline) }
                        Text(response.text)
                    }
                    Text("기기 내 번역은 iPhone 앱을 열고 사용하세요. 시스템 받아쓰기는 언어와 연결 상태에 따라 인터넷을 사용할 수 있습니다.")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("회의 번역")
        }
        .onChange(of: companion.response) { _, response in
            if response?.status == .completed { WKInterfaceDevice.current().play(.success) }
        }
    }
}
