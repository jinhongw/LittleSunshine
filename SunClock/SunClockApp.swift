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
      ContentView()
        .environment(appModel)
    }
    .windowStyle(.volumetric)
    .windowResizability(.contentMinSize)
    .persistentSystemOverlays(.hidden)
    .defaultSize(Size3D.init(width: 0.18, height: 0.09, depth: 0.18), in: .meters)
    
    WindowGroup(id: AppModel.ViewTag.about.name) {
      AboutView()
    }
    .defaultWindowPlacement { content, context in
      return WindowPlacement(.trailing(context.windows.last!), size: CGSize.init(width: 480, height: 600))
    }
  }
}
