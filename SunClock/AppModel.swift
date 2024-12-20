//
//  AppModel.swift
//  SunClock
//
//  Created by jinhong on 2024/12/13.
//

import SwiftUI

/// Maintains app-wide state
@MainActor
@Observable
class AppModel {
  let clockViewModel: ClockViewModel
  var navPath: [ViewTag] = []
  var persistentOverlays: Visibility = .visible
  
  enum ViewTag: String {
    case about
    var name: String { rawValue.capitalized }
  }
  
  init() {
    self.clockViewModel = ClockViewModel()
    self.clockViewModel.appModel = self
  }
}
