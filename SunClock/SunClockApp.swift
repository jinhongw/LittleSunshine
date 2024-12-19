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
    .defaultSize(Size3D.init(width: 0.18, height: 0.09, depth: 0.18), in: .meters)
  }
}
