//
//  ThreeQuarterVolumeKnob.swift
//  VolumeApp
//
//  Created by Corey Lofthus on 4/10/25.
//

import SwiftUI

// MARK: - Three-Quarter Volume Knob (270° Active Range)
//
// The knob’s active range is 270° of rotation, starting at 225° (volume=0)
// and ending at –45° (which is effectively 315° in circle terms; volume=1).
//
struct ThreeQuarterVolumeKnob: View {
    @Binding var volume: Double
    
    /// The current knob angle in our “knob space.”
    /// volume = (225 - knobAngle) / 270
    ///  → knobAngle=225 at volume=0, knobAngle=–45 at volume=1.
    @State private var knobAngle: Double = 225
    
    @State private var isAligned = false
    
    var body: some View {
        GeometryReader { geo in
            let size   = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: size / 2, y: size / 2)
            let radius = size * 0.45
            
            ZStack {
                // 1) Background circle

                Circle()
                    .foregroundStyle(Color.gray)
                Circle()
                    .foregroundStyle(.ultraThinMaterial.opacity(1))
                    .blur(radius: radius * 0.1)
               
                
                // 2) Arc from 225° down to knobAngle (clockwise).
                ArcShape(startAngle: 225, endAngle: -45)
                    .stroke(
                        Color.gray,
                        style: StrokeStyle(lineWidth: size * 0.06, lineCap: .round)
                    )
                    .blur(radius: 1)
                ArcShape(startAngle: 225, endAngle: knobAngle)
                    .stroke(
                        Color.orange,
                        style: StrokeStyle(lineWidth: size * 0.06, lineCap: .round, dash: [size * 0.001, size * 0.08])
                    )
                    .blur(radius: size * 0.01)


                    
//                    // Move pivot to circle center.
//                    .position(x: center.x, y: center.y)
                ArcShape(startAngle: 225, endAngle: -45)
                    .stroke(
                        .ultraThinMaterial.opacity(1),
                        style: StrokeStyle(lineWidth: size * 0.07, lineCap: .round)
                    )
                    .blur(radius: 1)
                    .blendMode(.hardLight)
                  
                Capsule()
                    .fill(Color.white)
                    .frame(width: size, height: size * 0.1)
                    .clipShape(Circle()
                        .offset(x: size - size * 0.08) // Shift clip to the right side
                        .size(width: size * 0.06, height: size * 0.06))
                    .rotationEffect(Angle(degrees: -knobAngle))
                    .blur(radius: size * 0.01)

            }
            .sensoryFeedback(.alignment, trigger: isAligned) { oldValue, newValue in
                        print("haptic feedback")
                       // Plays feedback only when the square aligns with a gridline, but didn't previously.
                    return !oldValue && newValue
                   }
            // Make the entire circle draggable.
            .contentShape(Circle())
            // Drag gesture to update the angle and volume.
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let newAngle = angleForDrag(location: value.location, center: center)
                        withAnimation(.bouncy(duration: 0.3)) {
                            knobAngle = newAngle
                        }
                        isAligned = aligned(at: newAngle)
                        
                        // Map the candidate angle [225..(–45)] to volume [0..1].
                        let newVol = (225 - newAngle) / 270
                        volume = max(0, min(1, newVol))
                        setSystemVolume(volume)
                    }
            )
            // When volume changes externally, update knobAngle.
            .onChange(of: volume) { newVal, oldVal in
                
                withAnimation(.bouncy(duration: 0.3)) {
                    knobAngle = 225 - (270 * newVal)
                }
               
            }
            // Initialize angle on appear
            .onAppear {
                withAnimation(.bouncy(duration: 0.3)) {
                    knobAngle = 225 - (270 * volume)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    /// Converts a drag location to an angle in [–45..225].
    /// We flip the y-axis for standard math orientation, then clamp to our 270° range.
    private func angleForDrag(location: CGPoint, center: CGPoint) -> Double {
        let dx = location.x - center.x
        let dy = center.y - location.y  // Flip y
        
        var rawAngle = atan2(dy, dx) * 180 / .pi
        if rawAngle < 0 { rawAngle += 360 }
        
        // Convert angle to knob space
        if rawAngle > 270 {
            rawAngle -= 360  // e.g. 315 -> -45
        }
        
        // Clamp to valid range [-45, 225]
        let clampedAngle = min(225, max(-45, rawAngle))
        
        return clampedAngle
    }
    
    private func aligned(at: Double) -> Bool {
        //write a functin that returns true when the angle is divisible by 10 and between 225 and -45
        if at <= 225 && at >= -45 && at.truncatingRemainder(dividingBy: 10) == 0 {
            return true
        } else {
            return false
        }
        
    }
}
