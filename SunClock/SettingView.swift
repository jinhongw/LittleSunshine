//
//  SettingView.swift
//  SunClock
//
//  Created by jinhong on 2024/12/20.
//

import SwiftUI

struct SettingView: View {
  @Environment(AppModel.self) private var appModel
  @AppStorage("showCharacter") private var showCharacter = true
  @AppStorage("showCurrentTime") private var showCurrentTime = true
  @AppStorage("showSunriseSunset") private var showSunriseSunset = true
  var body: some View {
    List {
      Section {
        Toggle(isOn: $showCharacter) {
          Text("Show character")
        }
        .onChange(of: showCharacter) { oldValue, newValue in
          appModel.clockViewModel.onChangeOfShowCharacter(newValue: newValue)
        }
        Toggle(isOn: $showCurrentTime) {
          Text("Show current time")
        }
        Toggle(isOn: $showSunriseSunset) {
          Text("Show sunrise/sunset time")
        }
      }
    }
    .listStyle(.insetGrouped)
    .frame(width: 480)
    .navigationTitle("Settings")
  }
}

#Preview {
  NavigationStack {
    SettingView()
      .padding(.vertical, 36)
  }
}
