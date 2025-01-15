import SwiftUI
import UIKit

struct OnboardingEmailView: View {
  @Binding var email: String
  @State private var isValid: Bool = true
  let onSubmit: (String) -> Void

  var body: some View {
    VStack(spacing: 40) {
      Color.clear.frame(height: 80)

      VStack(spacing: 32) {

        HStack(spacing: 0) {
          Text("Crush ")
            .font(.system(size: 40, weight: .black))
            .foregroundColor(ColorTheme.primaryLight)
          Text("Your Race")
            .font(.system(size: 40, weight: .black))
            .foregroundColor(ColorTheme.primary)

        }
        VStack(spacing: 24) {
          Text("Welcome! Let's get started")
            .font(.system(size: 18))
            .foregroundColor(ColorTheme.lightGrey)
          VStack(spacing: 8) {
            CustomTextField(text: $email, placeholder: "Enter your email")
              .frame(height: 24)
              .padding()
              .background(ColorTheme.darkDarkGrey)
              .cornerRadius(12)
              .overlay(
                RoundedRectangle(cornerRadius: 12)
                  .stroke(isValid ? ColorTheme.primary : ColorTheme.redPink, lineWidth: 1)
              )
            if !isValid {
              Text("Please enter a valid email")
                .foregroundColor(ColorTheme.redPink)
                .font(.system(size: 14))
                .transition(.opacity)
            }
          }
          Button(action: {
            if isValidEmail(email) {
              isValid = true
              onSubmit(email)
            } else {
              withAnimation {
                isValid = false
              }
            }
          }) {
            Text("Continue")
              .font(.system(size: 18, weight: .semibold))
              .foregroundColor(ColorTheme.white)
              .frame(maxWidth: .infinity)
              .padding()
              .background(ColorTheme.primary)
              .cornerRadius(12)
              .shadow(color: ColorTheme.primary.opacity(0.3), radius: 8, x: 0, y: 4)
          }
          .disabled(email.isEmpty)
          .opacity(email.isEmpty ? 0.6 : 1)
        }
      }
      .padding(32)

      Spacer()
    }
    .background(
      LinearGradient(
        gradient: Gradient(colors: [ColorTheme.black, ColorTheme.darkDarkGrey]),
        startPoint: .top,
        endPoint: .bottom
      )
    )
    .ignoresSafeArea()
  }

  private func isValidEmail(_ email: String) -> Bool {
    let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
    return emailPred.evaluate(with: email)
  }
}

struct CustomTextField: UIViewRepresentable {
  @Binding var text: String
  let placeholder: String

  func makeUIView(context: Context) -> UITextField {
    let textField = UITextField()
    textField.placeholder = placeholder
    textField.attributedPlaceholder = NSAttributedString(
      string: placeholder,
      attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray.withAlphaComponent(0.4)]
    )
    textField.textColor = UIColor.gray.withAlphaComponent(0.7)
    textField.delegate = context.coordinator
    textField.backgroundColor = .clear
    textField.autocapitalizationType = .none
    textField.keyboardType = .emailAddress
    return textField
  }

  func updateUIView(_ uiView: UITextField, context: Context) {
    uiView.text = text
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(text: $text)
  }

  class Coordinator: NSObject, UITextFieldDelegate {
    @Binding var text: String

    init(text: Binding<String>) {
      self._text = text
    }

    func textFieldDidChangeSelection(_ textField: UITextField) {
      text = textField.text ?? ""
    }
  }
}
