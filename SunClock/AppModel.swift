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
  var navPath: [ViewTag] = []
  
  enum ViewTag: String {
    case about
    var name: String { rawValue.capitalized }
  }
}
