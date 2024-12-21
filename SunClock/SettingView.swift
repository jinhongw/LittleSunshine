//
//  SettingView.swift
//  SunClock
//
//  Created by jinhong on 2024/12/20.
//

import RealityKit
import RealityKitContent
import SwiftUI

struct SettingView: View {
  @Environment(AppModel.self) private var appModel
  @AppStorage("showCharacter") private var showCharacter = true
  @AppStorage("showCurrentTime") private var showCurrentTime = true
  @AppStorage("showSunriseSunset") private var showSunriseSunset = true
  @AppStorage("selectCharacterIndex") private var selectCharacterIndex: Int = 1
  var body: some View {
    List {
      Section {
        Toggle(isOn: $showCurrentTime) {
          Text("Show current time")
        }
        Toggle(isOn: $showSunriseSunset) {
          Text("Show sunrise/sunset time")
        }
      } header: {
        Text("Time")
      }

      Section {
        Toggle(isOn: $showCharacter) {
          Text("Show character")
        }
        .onChange(of: showCharacter) { oldValue, newValue in
          appModel.clockViewModel.onChangeOfShowCharacter(newValue: newValue)
        }
        if showCharacter {
          selectCharacter
        }
      } header: {
        Text("Character")
      }
    }
    .listStyle(.insetGrouped)
    .frame(width: 480)
    .navigationTitle("Settings")
  }

  @MainActor
  @ViewBuilder
  private var selectCharacter: some View {
    VStack(alignment: .leading) {
      Text("Select character")
      VStack {
        HStack {
          VStack(spacing: 16) {
            Model3D(named: "PixelGirlCutePose", bundle: realityKitContentBundle) { model in
              model
                .resizable()
                .aspectRatio(contentMode: .fit)
            } placeholder: {
              ProgressView()
            }
            .frame(width: 100, height: 100)
            Button(action: {
              print(#function, "PixelGirlCutePose")
              selectCharacterIndex = 1
            }, label: {
              Image(systemName: selectCharacterIndex == 1 ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(selectCharacterIndex == 1 ? .primary : Color.gray)
            })
            .buttonStyle(BorderlessButtonStyle())
          }
          Spacer()
          VStack(spacing: 16) {
            Model3D(named: "PixelGirlStaticPose", bundle: realityKitContentBundle) { model in
              model
                .resizable()
                .aspectRatio(contentMode: .fit)
            } placeholder: {
              ProgressView()
            }
            .frame(width: 100, height: 100)
            Button(action: {
              print(#function, "PixelGirlStaticPose")
              selectCharacterIndex = 2
            }, label: {
              Image(systemName: selectCharacterIndex == 2 ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(selectCharacterIndex == 2 ? .primary : Color.gray)
            })
            .buttonStyle(BorderlessButtonStyle())
          }
          Spacer()
          VStack(spacing: 16) {
            Model3D(named: "PixelGirlCatPose", bundle: realityKitContentBundle) { model in
              model
                .resizable()
                .aspectRatio(contentMode: .fit)
            } placeholder: {
              ProgressView()
            }
            .frame(width: 100, height: 100)
            Button(action: {
              print(#function, "PixelGirlCatPose")
              selectCharacterIndex = 3
            }, label: {
              Image(systemName: selectCharacterIndex == 3 ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(selectCharacterIndex == 3 ? .primary : Color.gray)

            })
            .buttonStyle(BorderlessButtonStyle())
            .hoverEffect(.lift)
          }
        }
        .padding(.horizontal, 20)
        .onChange(of: selectCharacterIndex) { oldValue, newValue in
          appModel.clockViewModel.onChangeOfSelectCharacter(newValue: newValue)
        }
        VStack(spacing: 4) {
          Text("Komi san fan-art by Kvemon, licensed under CC BY 4.0")
            .font(.caption)
          Link("Learn More", destination: URL(string: "https://skfb.ly/oRsuK")!)
            .font(.caption)
            .foregroundStyle(.link)
        }
      }
    }
  }
}

#Preview {
  NavigationStack {
    SettingView()
      .environment(AppModel())
      .padding(.vertical, 36)
  }
}
