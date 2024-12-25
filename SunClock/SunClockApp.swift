//
//  SunClockApp.swift
//  SunClock
//
//  Created by jinhong on 2024/12/13.
//

import SwiftUI

@main
struct SunClockApp: App {
  @State private var appModel = AppModel()
  @Environment(\.scenePhase) private var scenePhase

  var body: some Scene {
    WindowGroup {
      ClockView(viewModel: appModel.clockViewModel)
        .environment(appModel)
        .volumeBaseplateVisibility(appModel.persistentOverlays == .hidden ? .hidden : .visible)
        .onChange(of: scenePhase, { oldValue, newValue in
          if newValue == .active, let location = appModel.clockViewModel.location {
            Task {
              print(#function, "scenePhase \(scenePhase) \(location)")
              await appModel.clockViewModel.fetchSunriseSunset(for: location)
            }
          }
        })
    }
    .windowStyle(.volumetric)
    .defaultWorldScaling(.automatic)
    .volumeWorldAlignment(.gravityAligned)
    .windowResizability(.contentSize)
    .persistentSystemOverlays(appModel.persistentOverlays)
    .defaultSize(Size3D.init(width: 0.18, height: 0.09, depth: 0.18), in: .meters)
    .defaultWindowPlacement { content, context in
      return WindowPlacement(.utilityPanel)
    }
    
    WindowGroup(id: AppModel.ViewTag.about.name) {
      AboutView()
        .environment(appModel)
    }
    .windowResizability(.contentSize)
    .defaultWindowPlacement { content, context in
      return WindowPlacement(.trailing(context.windows.last!), size: CGSize.init(width: 480, height: 680))
    }
  }
}
