//
//  CreditsView.swift
//  SunClock
//
//  Created by jinhong on 2024/12/20.
//

import RealityKit
import RealityKitContent
import SwiftUI

struct CreditsView: View {
  var body: some View {
    ScrollView {
      VStack(spacing: 24) {
        Model3D(named: "PixelGirlScene", bundle: realityKitContentBundle) { model in
          model
            .resizable()
            .aspectRatio(contentMode: .fit)
        } placeholder: {
          ProgressView()
        }
        .frame(width: 180, height: 180)
        VStack(spacing: 4) {
          Text("Komi san fan-art by Kvemon, licensed under CC BY 4.0")
          Link("Learn More", destination: URL(string: "https://skfb.ly/oRsuK")!)
        }
      }
    }
    .navigationTitle("Credits")
  }
}

#Preview {
  NavigationStack {
    CreditsView()
      .padding(.vertical, 38)
  }
}
