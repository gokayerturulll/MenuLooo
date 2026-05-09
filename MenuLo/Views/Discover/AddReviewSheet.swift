//
//  AddReviewSheet.swift
//  MenuLo
//
//  3 kategori (Lezzet, Servis, Ambiyans) için opsiyonel yıldız puanlama +
//  serbest metin alan modal. ReviewViewModel'in form state'ine bağlanır;
//  Gönder butonuna basıldığında submitDraft çağrılır ve sheet kapanır.
//

import SwiftUI

struct AddReviewSheet: View {
    let restaurantId: Int
    let restaurantName: String
    @ObservedObject var viewModel: ReviewViewModel

    @Environment(\.dismiss) private var dismiss
    @FocusState private var isEditorFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: MenuLoTheme.Spacing.lg) {
                    headerCard

                    ratingGroup(title: "Lezzet",
                                iconName: "fork.knife",
                                value: $viewModel.draftTaste)
                    ratingGroup(title: "Servis",
                                iconName: "hand.raised.fill",
                                value: $viewModel.draftService)
                    ratingGroup(title: "Ambiyans",
                                iconName: "sparkles",
                                value: $viewModel.draftAttitude)

                    contentEditor

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(MenuLoTheme.Fonts.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 4)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Yorum Yap")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        isEditorFocused = false
                        Task {
                            let ok = await viewModel.submitDraft(restaurantId: restaurantId)
                            if ok { dismiss() }
                        }
                    } label: {
                        if viewModel.isSubmitting {
                            ProgressView()
                        } else {
                            Text("Gönder").fontWeight(.semibold)
                        }
                    }
                    .disabled(viewModel.isSubmitting)
                }
            }
        }
    }

    // MARK: - Subsections

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(restaurantName)
                .font(MenuLoTheme.Fonts.subtitle)
                .foregroundColor(.primary)
            Text("Lezzet, servis ve ambiyans için isteğe bağlı puan ver. En az bir alanı doldurman yeterli.")
                .font(MenuLoTheme.Fonts.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: MenuLoTheme.CornerRadius.medium))
    }

    private func ratingGroup(title: String,
                             iconName: String,
                             value: Binding<Int?>) -> some View {
        VStack(alignment: .leading, spacing: MenuLoTheme.Spacing.sm) {
            HStack(spacing: 6) {
                Image(systemName: iconName)
                    .foregroundColor(MenuLoTheme.Colors.primary)
                Text(title)
                    .font(MenuLoTheme.Fonts.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
                if let v = value.wrappedValue {
                    Button {
                        value.wrappedValue = nil
                    } label: {
                        Text("Temizle (\(v)/5)")
                            .font(MenuLoTheme.Fonts.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            StarPicker(value: value)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: MenuLoTheme.CornerRadius.medium))
    }

    private var contentEditor: some View {
        VStack(alignment: .leading, spacing: MenuLoTheme.Spacing.sm) {
            Text("Yorumun")
                .font(MenuLoTheme.Fonts.body)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            TextEditor(text: $viewModel.draftContent)
                .focused($isEditorFocused)
                .frame(minHeight: 140)
                .padding(8)
                .background(Color(.tertiarySystemFill))
                .clipShape(RoundedRectangle(cornerRadius: MenuLoTheme.CornerRadius.medium))
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: MenuLoTheme.CornerRadius.medium))
    }
}

// MARK: - Star Picker

private struct StarPicker: View {
    @Binding var value: Int?

    var body: some View {
        HStack(spacing: MenuLoTheme.Spacing.sm) {
            ForEach(1...5, id: \.self) { i in
                Button {
                    // Aynı yıldıza ikinci tap → puanı temizle (hızlı vazgeçme).
                    value = (value == i) ? nil : i
                } label: {
                    Image(systemName: i <= (value ?? 0) ? "star.fill" : "star")
                        .font(.system(size: 28))
                        .foregroundColor(i <= (value ?? 0) ? .yellow : Color(.tertiaryLabel))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(i) yıldız")
            }
        }
    }
}
