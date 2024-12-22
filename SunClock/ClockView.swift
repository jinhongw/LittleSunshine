//
//  ContentView.swift
//  SunClock
//
//  Created by jinhong on 2024/12/13.
//

import RealityKit
import RealityKitContent
import SwiftUI
import TipKit

struct ClockView: View {
  @Environment(AppModel.self) private var appModel
  @Environment(\.openWindow) private var openWindow
  @Environment(\.dismissWindow) private var dismissWindow
  @AppStorage("showCurrentTime") private var showCurrentTime = true
  @AppStorage("showSunriseSunset") private var showSunriseSunset = true
  let viewModel: ClockViewModel
  var tipGroup = TipGroup {
    WelcomeTip()
    LittleTipsTip()
  }

  @State private var currentTime = Date()
  private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

  var body: some View {
    VStack {
      if let _ = viewModel.sunrise,
         let _ = viewModel.sunset
      {
        clockView
          .toolbar {
            if appModel.persistentOverlays == .visible {
              ToolbarItem {
                aboutButton
              }
            }
          }
      } else if viewModel.location == nil {
        fetchingLocation
      } else {
        fetchingSunriseSunset
      }
    }
    .task {
      // Configure and load your tips at app launch.
      do {
        try Tips.configure()
      } catch {
        // Handle TipKit errors
        print("Error initializing TipKit \(error.localizedDescription)")
      }
    }
  }

  @MainActor
  @ViewBuilder
  private var clockView: some View {
    RealityView { content, attachments in
      await content.add(viewModel.setUpContentEntity())
      if let timeText = attachments.entity(for: "timeText"),
         let tips = attachments.entity(for: "tips"),
         let sunEarthGroup = viewModel.contentEntity.findEntity(named: "Sun_Earth_Group"),
         let character = viewModel.contentEntity.findEntity(named: "Characters")
      {
        timeText.position = .init(x: 0, y: 0.15, z: -0.12)
        sunEarthGroup.addChild(timeText)

        tips.position = .init(x: 0, y: 0.3, z: 0)
        tips.scale = .init(x: 2, y: 2, z: 2)
        character.addChild(tips)
      }
    } attachments: {
      Attachment(id: "timeText") {
        timeText
      }
      Attachment(id: "tips") {
        TipView(tipGroup.currentTip, arrowEdge: .bottom)
          .tipBackground(.ultraThickMaterial)
      }
    }
    .gesture(
      TapGesture().targetedToAnyEntity().onEnded { _ in
        print(#function, "onTapGesture \(appModel.persistentOverlays)")
        if appModel.persistentOverlays == .visible {
          appModel.persistentOverlays = .hidden
        } else {
          appModel.persistentOverlays = .visible
        }
      }
    )
  }

  @MainActor
  @ViewBuilder
  private var fetchingLocation: some View {
    VStack {
      ProgressView {
        Text("Fetching location...")
      }
      Link(destination: URL(string: UIApplication.openSettingsURLString)!) {
        Text("开启位置权限")
      }
      .font(.caption)
    }
  }

  @MainActor
  @ViewBuilder
  private var fetchingSunriseSunset: some View {
    ProgressView {
      Text("Fetching sunrise and sunset...")
    }
  }

  @MainActor
  @ViewBuilder
  private var timeText: some View {
    VStack {
      if showCurrentTime {
        Text("\(currentTime.formatted(date: .omitted, time: .shortened))")
          .font(.system(size: 80, weight: .heavy))
          .lineLimit(1)
          .onReceive(timer) { newTime in
            print(#function, "newTime \(newTime)")
            currentTime = newTime
          }
      }
      if showSunriseSunset,
         let sunset = viewModel.sunset,
         let sunrise = viewModel.sunrise
      {
        HStack {
          Spacer(minLength: 0)
          HStack(spacing: 12) {
            HStack {
              Image(systemName: "sunset")
              Text("\(sunset.formatted(date: .omitted, time: .shortened))")
                .lineLimit(1)
            }
            HStack {
              Image(systemName: "sunrise")
              Text("\(sunrise.formatted(date: .omitted, time: .shortened))")
                .lineLimit(1)
            }
          }
          Spacer(minLength: 0)
        }
        .font(.system(size: 30, weight: .heavy))
      }
    }.frame(minWidth: 500)
  }

  @MainActor
  @ViewBuilder
  private var aboutButton: some View {
    Button(action: {
      openWindow(id: AppModel.ViewTag.about.name)
    }, label: {
      Text("About")
    })
  }
}

struct WelcomeTip: Tip {
  @Parameter
  static var alreadyDiscovered: Bool = false

  var title: Text {
    Text("欢迎使用 Little Sunshine")
  }

  var message: Text? {
    Text("仔细观察太阳、地球和人物的位置，你一定能明白其中的奥秘。")
      .foregroundStyle(.white)
  }

  var image: Image? {
    Image(systemName: "quote.bubble")
  }

  var rules: [Rule] {
    [
      #Rule(Self.$alreadyDiscovered) { $0 == false },
    ]
  }
}

struct LittleTipsTip: Tip {
  @Parameter
  static var alreadyDiscovered: Bool = false

  var title: Text {
    Text("小提示")
  }

  var message: Text? {
    Text("轻点地球可以隐藏底部导航和窗口控件，让界面更加简洁！")
      .foregroundStyle(.white)
  }

  var image: Image? {
    Image(systemName: "quote.bubble")
  }

  var rules: [Rule] {
    [
      #Rule(Self.$alreadyDiscovered) { $0 == false },
    ]
  }
}

#Preview(windowStyle: .volumetric) {
  ClockView(viewModel: ClockViewModel())
    .environment(AppModel())
}
