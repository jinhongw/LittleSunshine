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

  override init() {
    super.init()
    setupLocationManager()
    startTimer()
  }
  
  func onChangeOfShowCharacter(newValue: Bool) {
    guard let charater = contentEntity.findEntity(named: "pixel_girl") else { return }
    if newValue {
      charater.components.set(OpacityComponent(opacity: 1))
    } else {
      charater.components.set(OpacityComponent(opacity: 0))
    }
  }
  
  func setUpStorageValue() {
    if let showCharacter = UserDefaults.standard.value(forKey: "showCharacter") as? Bool {
      onChangeOfShowCharacter(newValue: showCharacter)
    } else {
      onChangeOfShowCharacter(newValue: true)
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

  deinit {
//    timer?.invalidate()
  }

  /// 设置 LocationManager
  private func setupLocationManager() {
    locationManager.delegate = self
    locationManager.requestWhenInUseAuthorization()
    locationManager.startUpdatingLocation()
    print(#function, "setupLocationManager")
  }

  /// CLLocationManagerDelegate - 更新位置
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

  /// 获取当前地点的日出和日落时间
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
    } else {
      print(#function, "不在当天日出日落范围内，太阳归位到默认位置")
      angleRadians = 0
    }
    if animated {
      sunGroup.move(to: .init(rotation: simd_quatf(angle: angleRadians, axis: [0, 0, 1])), relativeTo: sunGroup.parent, duration: animated ? 1 : 0)
    } else {
      sunGroup.orientation = simd_quatf(angle: angleRadians, axis: [0, 0, 1])
    }
  }

  @MainActor
  func rotateEarthModel()
  {
    guard let earthEntity = earthEntity,
          let currentPointEntity = currentPointEntity
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

    let radius: Float = 0.1
    currentPointEntity.position = userDirection * radius

    earthEntity.transform.rotation = rotationQuaternion
//    earthEntity.move(to: .init(rotation: rotationQuaternion), relativeTo: earthEntity.parent, duration: 1)
  }
}
