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
  @Environment(\.openWindow) var openWindow
  @Environment(\.dismissWindow) var dismissWindow
  @State private var isShowing = false
  var body: some View {
    if let _ = clockViewModel.sunrise,
       let _ = clockViewModel.sunset
    {
      clockView
        .toolbar {
          ToolbarItem {
            aboutButton
          }
        }
    } else if clockViewModel.location == nil {
      fetchingLocation
    } else {
      fetchingSunriseSunset
    }
  }

  @MainActor
  @ViewBuilder
  private var clockView: some View {
    RealityView { content, attachments in
      await content.add(clockViewModel.setUpContentEntity())
      if let timeText = attachments.entity(for: "timeText"), let sunEarthGroup = clockViewModel.contentEntity.findEntity(named: "Sun_Earth_Group") {
        timeText.position = .init(x: 0, y: 0.15, z: -0.12)
        sunEarthGroup.addChild(timeText)
      }
    } attachments: {
      Attachment(id: "timeText") {
        timeText
      }
    }
  }
  
  @MainActor
  @ViewBuilder
  private var fetchingLocation: some View {
    ProgressView {
      Text("Fetching location...")
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
      Text("\(Date().formatted(date: .omitted, time: .shortened))")
        .font(.system(size: 80, weight: .heavy))
        .lineLimit(1)
      if let sunset = clockViewModel.sunset, let sunrise = clockViewModel.sunrise {
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

#Preview(windowStyle: .volumetric) {
  ContentView()
    .environment(AppModel())
}
