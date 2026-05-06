import SwiftUI

struct APILoginView: View {
    @AppStorage("authToken") private var token: String = ""
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("MenuLo'ya Hoş Geldiniz")
                .font(.title)
                .bold()
            
            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
            
            SecureField("Şifre", text: $password)
                .textFieldStyle(.roundedBorder)
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.footnote)
            }
            
            Button(action: {
                Task { await loginUser() }
            }) {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Giriş Yap")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
    }
    
    private func loginUser() async {
        isLoading = true
        errorMessage = ""
        do {
            let response = try await NetworkManager.shared.login(email: email, password: password)
            if response.success, let jwt = response.token {
                token = jwt
            } else {
                errorMessage = response.message ?? "Bilinmeyen bir hata oluştu."
            }
        } catch {
            errorMessage = "Ağ hatası: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
