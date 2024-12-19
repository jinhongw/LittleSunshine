//
//  ContentView.swift
//  SunClock
//
//  Created by jinhong on 2024/12/13.
//

import RealityKit
import RealityKitContent
import SwiftUI

struct ContentView: View {
  @StateObject private var clockViewModel = ClockViewModel()
  var body: some View {
    VStack {
//      Slider(value: $clockViewModel.latitude, in: -90...90) {
//        Text("latitude")
//      } onEditingChanged: { _ in
//        clockViewModel.rotateEarthModel()
//      }
//      Text("\(clockViewModel.latitude)")
//      Slider(value: $clockViewModel.longitude, in: -180...180) {
//        Text("longitude")
//      } onEditingChanged: { _ in
//        clockViewModel.rotateEarthModel()
//      }
//      Text("\(clockViewModel.longitude)")
      if let _ = clockViewModel.sunrise,
         let _ = clockViewModel.sunset
      {
        RealityView { content in
          await content.add(clockViewModel.setUpContentEntity())
        }
      } else if clockViewModel.location == nil {
        ProgressView {
          Text("Fetching location...")
        }
      } else {
        ProgressView {
          Text("Fetching sunrise and sunset...")
        }
      }
    }
  }
}

#Preview(windowStyle: .volumetric) {
  ContentView()
    .environment(AppModel())
}
