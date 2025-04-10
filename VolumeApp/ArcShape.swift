//
//  ArcShape.swift
//  VolumeApp
//
//  Created by Corey Lofthus on 4/10/25.
//

import SwiftUI


// MARK: - ArcShape

/// Draws an arc from startAngle to endAngle (in degrees) in a clockwise direction.
/// If endAngle is negative, SwiftUI automatically treats it as e.g. 315°, producing a continuous arc.
struct ArcShape: Shape {
    var startAngle: Double
    var endAngle: Double
    
    var animatableData: Double {
        get { endAngle }
        set { endAngle = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) * 0.45
        
        var path = Path()
        
        // Clamp angles to avoid wrap-around
        let safeEndAngle = min(endAngle, startAngle)
        
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(-startAngle),
            endAngle: .degrees(-safeEndAngle),
            clockwise: false
        )
        return path
    }
}
