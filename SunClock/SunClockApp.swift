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

  var body: some Scene {
    WindowGroup {
      ClockView(viewModel: appModel.clockViewModel)
        .environment(appModel)
    }
    .windowStyle(.volumetric)
    .windowResizability(.contentMinSize)
    .persistentSystemOverlays(appModel.persistentOverlays)
    .defaultSize(Size3D.init(width: 0.18, height: 0.09, depth: 0.18), in: .meters)
    
    WindowGroup(id: AppModel.ViewTag.about.name) {
      AboutView()
        .environment(appModel)
    }
    .defaultWindowPlacement { content, context in
      return WindowPlacement(.trailing(context.windows.last!), size: CGSize.init(width: 480, height: 600))
    }
  }
}
