import SwiftUI

struct ErrorView: View {
  var body: some View {
    VStack(spacing: 24) {
      Spacer()
      Spacer()

      VStack(spacing: 24) {
        Image(systemName: "exclamationmark.triangle")
          .font(.system(size: 32))
          .foregroundColor(ColorTheme.midLightGrey)

        VStack(spacing: 12) {
          Text("Something's not quite right")
            .font(.system(size: 20, weight: .semibold))
            .foregroundColor(ColorTheme.lightGrey)

          Text("Looks like we can't find your data right now. Don't worry, we're working on it!")
            .font(.system(size: 16))
            .foregroundColor(ColorTheme.midLightGrey)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
        }
      }
      .padding(40)
      .background(ColorTheme.darkDarkGrey)
      .cornerRadius(12)
      .padding(.horizontal)

      Spacer()
      Spacer()
      Spacer()
    }
    .frame(maxHeight: .infinity)
  }
}
