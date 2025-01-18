import SwiftUI

struct OnboardingCarousel: View {
  @Environment(\.dismiss) private var dismiss
  @State private var currentPage: Int = 0
  let showCloseButton: Bool

  let pages: [(image: String, title: String, subtitle: String)] = [
    ("AppDashboard", "Next Gen Training", "Our AI curates your week and gives you feedback daily"),
    (
      "AppDashboardAlt", "Achieve Your Goals",
      "Training plans updated weekly based on your training history"
    ),
    (
      "AppProfile", "Tailored For You",
      "Update your preferences to get the most out of your training"
    ),
  ]

  var body: some View {
    ZStack {
      LinearGradient(
        gradient: Gradient(colors: [ColorTheme.darkBlack, ColorTheme.black]),
        startPoint: .top,
        endPoint: .bottom
      )
      .edgesIgnoringSafeArea(.all)

      VStack(spacing: 0) {
        if showCloseButton {
          closeButton
            .padding(.top, 8)
        }

        TabView(selection: $currentPage) {
          ForEach(0..<pages.count, id: \.self) { index in
            OnboardingPage(
              image: pages[index].image,
              title: pages[index].title,
              subtitle: pages[index].subtitle
            )
            .tag(index)
          }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

        pageControl
          .padding(.top, 12)
          .padding(.bottom, 8)
      }
    }
  }

  private var closeButton: some View {
    HStack {
      Spacer()
      Button(action: { dismiss() }) {
        Image(systemName: "xmark")
          .foregroundColor(ColorTheme.lightGrey)
          .font(.system(size: 20, weight: .semibold))
      }
      .padding(.trailing)
      .padding(.top, 4)
    }
  }

  private var pageControl: some View {
    HStack(spacing: 8) {
      ForEach(0..<pages.count, id: \.self) { index in
        Circle()
          .fill(currentPage == index ? ColorTheme.primary : ColorTheme.darkGrey)
          .frame(width: 8, height: 8)
          .animation(.easeInOut, value: currentPage)
      }
    }
  }
}

struct OnboardingPage: View {
  let image: String
  let title: String
  let subtitle: String

  var body: some View {
    VStack(spacing: 0) {
      ZStack(alignment: .bottom) {
        Image(image)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(maxHeight: UIScreen.main.bounds.height * 0.75)
          .clipShape(RoundedRectangle(cornerRadius: 24))
          .padding(.horizontal, 16)
          .shadow(
            color: Color.black.opacity(0.12),
            radius: 25,
            x: 0,
            y: 10
          )
          .overlay(
            LinearGradient(
              gradient: Gradient(
                colors: [
                  .clear,
                  .black.opacity(0.8),
                ]
              ),
              startPoint: .center,
              endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 24))
          )

        VStack(spacing: 8) {
          Text(title)
            .font(.system(size: 32, weight: .bold))
            .foregroundColor(ColorTheme.white)
            .padding(.horizontal)

          Text(subtitle)
            .font(.system(size: 16))
            .foregroundColor(ColorTheme.lightGrey)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .padding(.bottom, 16)
      }
    }
  }
}

#Preview {
  OnboardingCarousel(showCloseButton: true)
}
