//
//  Utilities.swift
//  SunClock
//
//  Created by jinhong on 2024/12/24.
//

import Foundation
import Spatial

extension Size3D {
  static func / (lhs: Size3D, rhs: Size3D) -> Size3D {
      return Size3D(width: lhs.width / rhs.width, height: lhs.height / rhs.height, depth: lhs.depth / rhs.depth)
  }
}
