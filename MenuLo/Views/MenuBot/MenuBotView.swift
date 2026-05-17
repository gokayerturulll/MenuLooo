//
//  MenuBotView.swift
//  MenuLo
//
//  AI Garson chat ekranı. Kullanıcı bir restoran context'inde mesaj atar,
//  backend pgvector ile alakalı menü öğelerini bulup gemini-1.5-flash ile
//  yanıt üretir.
//

import SwiftUI

// MARK: - Chat Message Modeli
struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let role: Role
    let text: String
    let timestamp: Date = Date()

    enum Role { case user, bot }
}

// MARK: - MenuBotView
struct MenuBotView: View {
    @Environment(\.dismiss) private var dismiss

    /// nil → Genel Gurme Modu (tüm restoranlarda arama).
    /// Int  → Spesifik Restoran Modu (sadece bu restoranın menüsünde arama).
    let restaurantId: Int?

    @State private var messages: [ChatMessage]
    @State private var input: String = ""
    @State private var isWaiting: Bool = false
    @FocusState private var inputFocused: Bool

    init(restaurantId: Int? = nil) {
        self.restaurantId = restaurantId

        // Karşılama mesajı moda göre değişir — kullanıcı doğru mental model'i kursun
        let welcomeText: String = restaurantId != nil
            ? "Merhaba! Ben MenuBot 🤖 Bu restoranın menüsü hakkında ne sormak istersin? "
              + "Bütçen, damak tadın veya diyetin için önerilerde bulunabilirim."
            : "Merhaba! Ben MenuBot 🤖 Hangi semtte ne yemek arıyorsun? "
              + "Tüm MenuLo'dan sana özel öneriler sunabilirim — bütçe, diyet veya konum belirt yeter."

        _messages = State(initialValue: [
            ChatMessage(role: .bot, text: welcomeText)
        ])
    }

    private var canSend: Bool {
        !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isWaiting
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                chatList
                Divider()
                inputBar
            }
            .background(MenuLoTheme.Colors.backgroundLight.ignoresSafeArea())
            .navigationTitle("MenuBot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.title3)
                    }
                }
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .foregroundColor(MenuLoTheme.Colors.primary)
                        Text("MenuBot")
                            .font(MenuLoTheme.Fonts.button)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }

    // MARK: - Chat List
    private var chatList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: MenuLoTheme.Spacing.md) {
                    ForEach(messages) { msg in
                        ChatBubble(message: msg)
                            .id(msg.id)
                    }
                    if isWaiting {
                        TypingIndicator()
                            .id("typing-indicator")
                    }
                }
                .padding(.horizontal, MenuLoTheme.Spacing.md)
                .padding(.vertical, MenuLoTheme.Spacing.md)
            }
            .onChange(of: messages.count) { _, _ in
                scrollToEnd(with: proxy)
            }
            .onChange(of: isWaiting) { _, _ in
                scrollToEnd(with: proxy)
            }
        }
    }

    // MARK: - Input Bar
    private var inputBar: some View {
        HStack(spacing: MenuLoTheme.Spacing.sm) {
            HStack(spacing: 8) {
                Image(systemName: "text.bubble.fill")
                    .foregroundColor(.secondary)
                    .font(.footnote)

                TextField("MenuBot'a sor…", text: $input, axis: .vertical)
                    .font(MenuLoTheme.Fonts.body)
                    .lineLimit(1...4)
                    .focused($inputFocused)
                    .submitLabel(.send)
                    .onSubmit { send() }
            }
            .padding(.horizontal, MenuLoTheme.Spacing.md)
            .padding(.vertical, 10)
            .background(Color(.tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: MenuLoTheme.CornerRadius.large))

            Button(action: send) {
                ZStack {
                    Circle()
                        .fill(
                            canSend
                                ? AnyShapeStyle(
                                    LinearGradient(
                                        colors: [MenuLoTheme.Colors.primary, MenuLoTheme.Colors.accentOrange],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    )
                                  )
                                : AnyShapeStyle(Color(.tertiarySystemFill))
                        )
                        .frame(width: 40, height: 40)
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(canSend ? .white : .secondary)
                }
            }
            .disabled(!canSend)
            .animation(.easeInOut(duration: 0.15), value: canSend)
        }
        .padding(.horizontal, MenuLoTheme.Spacing.md)
        .padding(.vertical, MenuLoTheme.Spacing.sm)
        .background(.regularMaterial)
    }

    // MARK: - Actions
    private func send() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isWaiting else { return }

        input = ""
        messages.append(ChatMessage(role: .user, text: text))
        isWaiting = true

        Task { @MainActor in
            do {
                let answer = try await NetworkManager.shared.askMenuBot(
                    restaurantId: restaurantId,
                    message: text
                )
                isWaiting = false
                messages.append(ChatMessage(role: .bot, text: answer))
            } catch {
                isWaiting = false
                messages.append(ChatMessage(
                    role: .bot,
                    text: "Üzgünüm, şu an yanıt veremiyorum 😔\nHata: \(error.localizedDescription)"
                ))
            }
        }
    }

    private func scrollToEnd(with proxy: ScrollViewProxy) {
        let target: AnyHashable = isWaiting
            ? AnyHashable("typing-indicator")
            : AnyHashable(messages.last?.id ?? UUID())
        withAnimation(.easeOut(duration: 0.25)) {
            proxy.scrollTo(target, anchor: .bottom)
        }
    }
}

// MARK: - Chat Bubble
private struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.role == .bot {
                botAvatar
            } else {
                Spacer(minLength: 50)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 3) {
                Text(message.text)
                    .font(MenuLoTheme.Fonts.body)
                    .foregroundColor(message.role == .user ? .white : .primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(bubbleBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .frame(maxWidth: 280, alignment: message.role == .user ? .trailing : .leading)
                    .fixedSize(horizontal: false, vertical: true)

                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.7))
                    .padding(.horizontal, 4)
            }

            if message.role == .user {
                userAvatar
            } else {
                Spacer(minLength: 50)
            }
        }
    }

    @ViewBuilder
    private var bubbleBackground: some View {
        if message.role == .user {
            LinearGradient(
                colors: [MenuLoTheme.Colors.primary, MenuLoTheme.Colors.accentOrange],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        } else {
            Color(.secondarySystemBackground)
        }
    }

    private var botAvatar: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [MenuLoTheme.Colors.primary, MenuLoTheme.Colors.accentOrange],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .frame(width: 28, height: 28)
            Image(systemName: "sparkles")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
        }
    }

    private var userAvatar: some View {
        ZStack {
            Circle()
                .fill(MenuLoTheme.Colors.primary.opacity(0.15))
                .frame(width: 28, height: 28)
            Image(systemName: "person.fill")
                .font(.system(size: 13))
                .foregroundColor(MenuLoTheme.Colors.primary)
        }
    }
}

// MARK: - Typing Indicator
private struct TypingIndicator: View {
    @State private var phase: Int = 0
    private let timer = Timer.publish(every: 0.35, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [MenuLoTheme.Colors.primary, MenuLoTheme.Colors.accentOrange],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 28, height: 28)
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
            }

            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color.secondary.opacity(phase == i ? 1.0 : 0.3))
                        .frame(width: 7, height: 7)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            Spacer(minLength: 50)
        }
        .onReceive(timer) { _ in
            phase = (phase + 1) % 3
        }
    }
}

// MARK: - Preview
#Preview("General Gourmet") {
    MenuBotView()
}

#Preview("Specific Restaurant") {
    MenuBotView(restaurantId: 1)
}
