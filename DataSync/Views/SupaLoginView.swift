import SwiftUI
import Supabase

struct SupaLoginView: View {
    var onLogin: (() -> Void)? = nil     // <-- Add this line

    @State private var email = "240designworks@gmail.com"
    @State private var password = "qirbiC-migboq-nuvki3"
    @State private var error: String?
    @State private var isLoading = false
    @State private var loginSucceeded = false

    // Replace with your own!
    private var client: SupabaseClient {
        guard let url = URL(string: ENV.supabaseUrl) else {
            fatalError("Invalid SUPABASE_URL in ENV")
        }
        return SupabaseClient(
            supabaseURL: url,
            supabaseKey: ENV.supabasePublishableKey
        )
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Login with Supabase")
                .font(.title.bold())
            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .textContentType(.username)
                .frame(minWidth: 300)
            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
                .textContentType(.password)
                .frame(minWidth: 300)

            if let error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
            Button(action: loginUser) {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Sign In")
                        .fontWeight(.bold)
                }
            }
            .disabled(isLoading)

            if loginSucceeded {
                Text("Login Successful 🎉")
                    .foregroundColor(.green)
            }
        }
        .padding()
    }

    func loginUser() {
        error = nil
        loginSucceeded = false
        isLoading = true

        Task {
            do {
                let session = try await client.auth.signIn(email: email, password: password)
                print("User session: \(session)")
                loginSucceeded = true
                onLogin?()    // <--- Call this so app advances!
            } catch {
                self.error = error.localizedDescription
            }
            isLoading = false
        }
    }
}
