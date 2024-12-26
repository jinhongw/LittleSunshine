//
//  ClockViewModel.swift
//  SunClock
//
//  Created by jinhong on 2024/12/18.
//

import CoreLocation
import Foundation
import RealityKit
import RealityKitContent
import WeatherKit

@MainActor
@Observable
class ClockViewModel: NSObject, @preconcurrency CLLocationManagerDelegate {
  var sunrise: Date?
  var sunset: Date?
  var location: CLLocation?
  var latitude: Double = 0
  var longitude: Double = 0

  weak var appModel: AppModel?
  let contentEntity = Entity()

  private var timer: Timer?

  private let locationManager = CLLocationManager()
  private let weatherService = WeatherService()
  private var sunGroupEntity: Entity?
  private var earthEntity: Entity?
  private var currentPointEntity: Entity?

  private var floatingTimer: Timer?
  private let floatDistance: Float = 0.025
  private let floatDuration: Double = 5
  private var isFloating = true
  private var floatTotal = 150
  private var floatCount = 0

  override init() {
    super.init()
    print(#function, "ClockViewModel init")
    setupLocationManager()
    startTimer()
    startFloating()
  }

  func onChangeOfShowCharacter(newValue: Bool) {
    guard let charater = contentEntity.findEntity(named: "Characters") else { return }
    if newValue {
      charater.components.set(OpacityComponent(opacity: 1))
    } else {
      charater.components.set(OpacityComponent(opacity: 0))
    }
  }

  func onChangeOfSelectCharacter(newValue: Int) {
    guard let cutePosegirl = contentEntity.findEntity(named: "PixelGirlCutePose"),
          let staticPosegirl = contentEntity.findEntity(named: "PixelGirlStaticPose"),
          let catPosegirl = contentEntity.findEntity(named: "PixelGirlCatPose")
    else { return }
    if newValue == 1 {
      cutePosegirl.components.set(OpacityComponent(opacity: 1))
      staticPosegirl.components.set(OpacityComponent(opacity: 0))
      catPosegirl.components.set(OpacityComponent(opacity: 0))
    } else if newValue == 2 {
      cutePosegirl.components.set(OpacityComponent(opacity: 0))
      staticPosegirl.components.set(OpacityComponent(opacity: 1))
      catPosegirl.components.set(OpacityComponent(opacity: 0))
    } else if newValue == 3 {
      cutePosegirl.components.set(OpacityComponent(opacity: 0))
      staticPosegirl.components.set(OpacityComponent(opacity: 0))
      catPosegirl.components.set(OpacityComponent(opacity: 1))
    }
  }
  
  func onChangeOfEarthFloating(newValue: Bool) {
    if newValue {
      startFloating()
    } else {
      stopFloating()
    }
  }

  private func setUpStorageValue() {
    if let showCharacter = UserDefaults.standard.value(forKey: "showCharacter") as? Bool {
      onChangeOfShowCharacter(newValue: showCharacter)
    } else {
      onChangeOfShowCharacter(newValue: true)
    }

    if let selectCharacter = UserDefaults.standard.value(forKey: "selectCharacterIndex") as? Int {
      onChangeOfSelectCharacter(newValue: selectCharacter)
    } else {
      onChangeOfSelectCharacter(newValue: 1)
    }
    
    if let earthFloating = UserDefaults.standard.value(forKey: "earthFloating") as? Bool, !earthFloating {
      stopFloating()
    }
  }

  func setUpContentEntity() async -> Entity {
    guard let scene = try? await Entity(named: "Scene", in: realityKitContentBundle),
          let sunGroup = scene.findEntity(named: "Sun_Group"),
          let earth = scene.findEntity(named: "Earth")
    else { return contentEntity }
    scene.position = .init(x: 0, y: -0.11, z: 0)
    sunGroupEntity = sunGroup
    earthEntity = earth
    contentEntity.addChild(scene)
    adjustSunRotation(animated: false)
    rotateEarthModel()
    setUpStorageValue()
    return contentEntity
  }

  private func startTimer() {
    timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
      Task { [weak self] in
        await self?.adjustSunRotation()
      }
    }
  }

  private func startFloating() {
    floatingTimer = Timer.scheduledTimer(withTimeInterval: floatDuration / 2 / Double(floatTotal), repeats: true) { [weak self] _ in
      Task { [weak self] in
        await self?.floating()
      }
    }
  }
  
  private func stopFloating() {
    floatingTimer?.invalidate()
    guard let floatingEntity = contentEntity.findEntity(named: "Earth_Group") else { return }
    floatingEntity.move(to: Transform(translation: .zero), relativeTo: floatingEntity.parent, duration: 0.5)
  }

  @MainActor
  private func floating() {
    guard let floatingEntity = contentEntity.findEntity(named: "Earth_Group") else { return }
    if isFloating {
      floatCount += 1
    } else {
      floatCount -= 1
    }

    let targetPosition = SIMD3<Float>(0, floatDistance * Float(floatCount) / Float(floatTotal), 0)
    floatingEntity.move(to: Transform(translation: targetPosition), relativeTo: floatingEntity.parent, duration: floatDuration / 2 / Double(floatTotal))
    if floatCount == floatTotal {
      isFloating = false
    } else if floatCount == -floatTotal {
      isFloating = true
    }
  }

  private func setupLocationManager() {
    locationManager.delegate = self
    locationManager.requestWhenInUseAuthorization()
    locationManager.startUpdatingLocation()
    print(#function, "setupLocationManager")
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let latestLocation = locations.last else { return }
    location = latestLocation
    locationManager.stopUpdatingLocation()
    latitude = location?.coordinate.latitude ?? 0
    longitude = location?.coordinate.longitude ?? 0
    rotateEarthModel()
    Task {
      print(#function, "locationManager \(latestLocation.debugDescription)")
      await fetchSunriseSunset(for: latestLocation)
    }
  }

  func fetchSunriseSunset(for location: CLLocation) async {
    do {
      let weather = try await weatherService.weather(for: location)
      if let dailyForecast = weather.dailyForecast.first {
        print(#function, "sunrise \(String(describing: dailyForecast.sun.sunrise?.debugDescription))", "sunset \(String(describing: dailyForecast.sun.sunset?.debugDescription))")
        sunrise = dailyForecast.sun.sunrise
        sunset = dailyForecast.sun.sunset
        adjustSunRotation(animated: false)
      }
    } catch {
      print("Failed to fetch weather data: \(error)")
    }
  }

  @MainActor
  private func adjustSunRotation(animated: Bool = true) {
    guard let sunrise = sunrise, let sunset = sunset, let sunGroup = sunGroupEntity else { return }
    let now = Date()

    let previousDaySunset = Calendar.current.date(byAdding: .day, value: -1, to: sunset)!
    let nextDaySunrise = Calendar.current.date(byAdding: .day, value: 1, to: sunrise)!

    let angleRadians: Float
    if now >= sunrise && now <= sunset {
      let totalDaylightDuration = sunset.timeIntervalSince(sunrise)
      let elapsedTimeSinceSunrise = now.timeIntervalSince(sunrise)
      let rotationRatio = elapsedTimeSinceSunrise / totalDaylightDuration
      let angleDegrees = rotationRatio * 180.0
      angleRadians = Float(angleDegrees * .pi / 180)
      print(#function, "日出到日落区间 \(angleDegrees)")
    } else if now > sunset && now <= nextDaySunrise {
      let totalNightDuration = nextDaySunrise.timeIntervalSince(sunset)
      let elapsedTimeSinceSunset = now.timeIntervalSince(sunset)
      let rotationRatio = elapsedTimeSinceSunset / totalNightDuration
      let angleDegrees = 180.0 + rotationRatio * 180.0
      angleRadians = Float(angleDegrees * .pi / 180)
      print(#function, "日落到次日日出区间 \(angleDegrees) \(String(describing: sunGroup.parent?.name))")
    } else if now >= previousDaySunset && now < sunrise {
      let totalNightDuration = sunrise.timeIntervalSince(previousDaySunset)
      let elapsedTimeSincePreviousSunset = now.timeIntervalSince(previousDaySunset)
      let rotationRatio = elapsedTimeSincePreviousSunset / totalNightDuration
      let angleDegrees = 180.0 + rotationRatio * 180.0
      angleRadians = Float(angleDegrees * .pi / 180)
      print(#function, "昨日落日到今日日出区间 \(angleDegrees)")
  } else {
      print(#function, "不在当天日出日落范围内，太阳归位到默认位置")
      if let location = location {
        Task {
          print(#function, "Next day fetchSunriseSunset")
          self.sunrise = nil
          self.sunset = nil
          await fetchSunriseSunset(for: location)
        }
      }
      angleRadians = 0
    }
    if animated {
      sunGroup.move(to: .init(rotation: simd_quatf(angle: angleRadians, axis: [0, 0, 1])), relativeTo: sunGroup.parent, duration: animated ? 1 : 0)
    } else {
      sunGroup.orientation = simd_quatf(angle: angleRadians, axis: [0, 0, 1])
    }
  }

  @MainActor
  func rotateEarthModel() {
    guard let earthEntity = earthEntity
    else {
      print(#function, "No earthEntity/latitude")
      return
    }

    let lat = Float(latitude * .pi / 180)
    let lon = Float(longitude * .pi / 180)

    let x = Float(cos(lat) * sin(lon))
    let y = Float(sin(lat))
    let z = Float(cos(lat) * cos(lon))
    let userDirection = SIMD3<Float>(x, y, z)
    print(#function, "userDirection \(userDirection)")

    let targetDirection = SIMD3<Float>(0, 1, 0)

    let rotationAxis = simd_cross(userDirection, targetDirection)
    let normalizedAxis = simd_normalize(rotationAxis)

    let dotProduct = simd_dot(userDirection, targetDirection)
    let angle = acos(dotProduct)

    let rotationQuaternion = simd_quatf(angle: angle, axis: normalizedAxis)

    earthEntity.transform.rotation = rotationQuaternion
//    earthEntity.move(to: .init(rotation: rotationQuaternion), relativeTo: earthEntity.parent, duration: 1)
  }
}
