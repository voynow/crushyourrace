import SwiftUI

struct PricingSection: View {
  var body: some View {
    VStack(spacing: 20) {
      Text("Launch Price!")
        .font(.system(size: 18, weight: .bold))
        .foregroundColor(ColorTheme.primary)

      HStack(alignment: .firstTextBaseline, spacing: 8) {
        ZStack(alignment: .center) {
          Text("$10")
            .font(.system(size: 48, weight: .bold))
            .foregroundColor(ColorTheme.midDarkGrey)

          Rectangle()
            .frame(width: 110, height: 4)
            .foregroundColor(ColorTheme.midDarkGrey)
            .rotationEffect(.degrees(165))
        }
        .frame(height: 48)

        Text("$5")
          .font(.system(size: 48, weight: .bold))
          .foregroundColor(ColorTheme.white)

        Text("per month")
          .font(.system(size: 18))
          .foregroundColor(ColorTheme.midLightGrey)
      }

      Text("50% OFF")
        .font(.system(size: 13, weight: .bold))
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(ColorTheme.redPink.opacity(0.15))
        .foregroundColor(ColorTheme.redPink)
        .cornerRadius(6)
    }
    .padding(24)
    .background(ColorTheme.darkDarkGrey)
    .cornerRadius(20)
    .padding(.horizontal, 24)
    .padding(.vertical, 12)
  }
}

struct PremiumBenefits: View {
  var body: some View {
    VStack(spacing: 24) {
      premiumBenefit(
        icon: "person.2.fill",
        title: "Collaborate with the team",
        subtitle: "You will shape the future of this platform"
      )

      premiumBenefit(
        icon: "chart.line.uptrend.xyaxis",
        title: "Unlimited Access",
        subtitle: "All features, all the time (new features too!)"
      )

      premiumBenefit(
        icon: "heart.fill",
        title: "Support the development",
        subtitle: "Your support is invaluable to our team"
      )
    }
    .padding(.horizontal, 24)
  }

  private func premiumBenefit(icon: String, title: String, subtitle: String) -> some View {
    HStack(spacing: 16) {
      Image(systemName: icon)
        .font(.system(size: 24))
        .foregroundColor(ColorTheme.primary)
        .frame(width: 32)

      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.system(size: 18, weight: .semibold))
          .foregroundColor(ColorTheme.white)
        Text(subtitle)
          .font(.system(size: 12))
          .foregroundColor(ColorTheme.lightGrey)
      }
    }
    .frame(maxWidth: 300, alignment: .leading)
  }
}
