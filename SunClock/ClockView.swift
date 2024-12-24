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
  @AppStorage("showCurrentTime") private var showCurrentTime = true
  @AppStorage("showCurrentDate") private var showCurrentDate = false
  @AppStorage("showSunriseSunset") private var showSunriseSunset = true

  let viewModel: ClockViewModel
  var tipGroup = TipGroup {
    WelcomeTip()
    LittleTipsTip()
  }

  let defaultSize = Size3D(width: 320.0, height: 320.0, depth: 320.0)
  @State private var modelYRotation: Double = 0
  @State private var dragModelYRotation: Double = 0
  @State private var angle: Float = 0
  @State private var axisX: Float = 0
  @State private var axisY: Float = 1
  @State private var axisZ: Float = 0
  @State private var currentTime = Date()
  
  private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

  var body: some View {
    GeometryReader3D { proxy in
      let _ = print(#function, "proxy.size \(proxy.size) scaleEffect \(proxy.size / defaultSize)")
      VStack {
        if let _ = viewModel.sunrise,
           let _ = viewModel.sunset
        {
          clockView
            .scaleEffect(proxy.size / defaultSize)
            .toolbar {
              if appModel.persistentOverlays == .visible {
                ToolbarItem {
                  aboutButton
                }
                if modelYRotation != 0 {
                  ToolbarItem {
                    resetRotationButton
                  }
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
        configureTips()
      }
    }
  }

  @MainActor
  func configureTips() {
    do {
      try Tips.configure()
    } catch {
      print("Error initializing TipKit \(error.localizedDescription)")
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

        tips.position = .init(x: 0, y: 0.15, z: 0)
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
    .rotation3DEffect(.radians(modelYRotation), axis: (x: 0, y: 1, z: 0), anchor: .center)
    .rotation3DEffect(
      .degrees(Double(angle * 180 / .pi)),
      axis: (x: CGFloat(axisX), y: CGFloat(axisY), z: CGFloat(axisZ))
    )
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
    .gesture(
      DragGesture()
        .onChanged { value in
          let translation = value.translation
          let dampingFactor: CGFloat = 40.0 // Smaller damping factor for less damping effect
          let rootDegree: Double = 1.3
          let xAngle = -pow(abs(translation.height), 1.0 / rootDegree) / dampingFactor * (translation.height < 0 ? -1 : 1)
          let yAngle = pow(abs(translation.width), 1.0 / rootDegree) / dampingFactor * (translation.width < 0 ? -1 : 1)

          let xRotation = simd_quatf(angle: Float(xAngle), axis: SIMD3(1, 0, 0))
          let yRotation = simd_quatf(angle: Float(yAngle), axis: SIMD3(0, 1, 0))
          let currentDragRotation = simd_mul(xRotation, yRotation)
          withAnimation(.spring) {
            angle = currentDragRotation.angle
            axisX = currentDragRotation.axis.x
            axisY = currentDragRotation.axis.y
            axisZ = currentDragRotation.axis.z
          }
          dragModelYRotation = yAngle
        }
        .onEnded { _ in
          withAnimation(.spring) {
            angle = 0
            axisX = 0
            axisY = 1
            axisZ = 0
            modelYRotation += dragModelYRotation
          }
        }
    )
  }

  @MainActor
  @ViewBuilder
  private var fetchingLocation: some View {
    HStack {
      Spacer(minLength: 0)
      VStack {
        Spacer(minLength: 0)
        ProgressView {
          Text("Fetching location...")
        }
        Link(destination: URL(string: UIApplication.openSettingsURLString)!) {
          Text("开启位置权限")
        }
        .font(.caption)
        Spacer(minLength: 0)
      }
      Spacer(minLength: 0)
    }
  }

  @MainActor
  @ViewBuilder
  private var fetchingSunriseSunset: some View {
    VStack {
      Spacer(minLength: 0)
      HStack {
        Spacer(minLength: 0)
        ProgressView {
          Text("Fetching sunrise and sunset...")
        }
        Spacer(minLength: 0)
      }
      Spacer(minLength: 0)
    }
  }

  @MainActor
  @ViewBuilder
  private var timeText: some View {
    VStack {
      if showCurrentDate {
        Text("\(currentTime.formatted(date: .abbreviated, time: .omitted))")
          .font(.system(size: 30, weight: .heavy))
      }
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

  @MainActor
  @ViewBuilder
  private var resetRotationButton: some View {
    Button(action: {
      withAnimation(.spring) {
        modelYRotation = 0
      }
    }, label: {
      Text("Reset")
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
