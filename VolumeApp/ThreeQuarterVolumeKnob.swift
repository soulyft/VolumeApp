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
    
    @State private var lastVolume: Double = 0
    @State private var lastHapticStep: Int = 0
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    @State private var nextAvailableHapticTime: Date = Date()
    @State private var hapticHappened: Bool = false

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
                    .blur(radius:  1)
                ZStack{
                    ArcShape(startAngle: 225, endAngle: knobAngle)
                        .stroke(
                            Color.red.opacity(1),
                            style: StrokeStyle(lineWidth: size * 0.06, lineCap: .round, dash: [size * 0.001, size * 0.08])
                        )
                        .blur(radius: hapticHappened ? size * 0.1 : size * 0.02)
                     
                    
                    ArcShape(startAngle: 225, endAngle: knobAngle)
                        .stroke(
                            Color.orange,
                            style: StrokeStyle(lineWidth: size * 0.06, lineCap: .round, dash: [size * 0.001, size * 0.08])
                        )
                        .blur(radius: size * 0.01)

                    
                }
                .mask(
                    ArcShape(startAngle: 225, endAngle: -45)
                        .stroke(
                            .ultraThinMaterial.opacity(1),
                            style: StrokeStyle(lineWidth: size * 0.07, lineCap: .round)
                        )
                )
               
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
            // Make the entire circle draggable.
            .contentShape(Circle())
            .clipShape(Circle())
            // Drag gesture to update the angle and volume.
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let newAngle = angleForDrag(location: value.location, center: center)
                        withAnimation(.bouncy(duration: 0.3)) {
                            knobAngle = newAngle
                        }
                        
                        // Map the candidate angle [225..(–45)] to volume [0..1].
                        let newVol = (225 - newAngle) / 270
                        volume = max(0, min(1, newVol))
//                        setSystemVolume(volume)
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
              
                feedbackGenerator.prepare()
                withAnimation(.bouncy(duration: 0.3)) {
                    knobAngle = 225 - (270 * volume)
                }
            }
            .onChange(of: knobAngle) { newKnobAngle, oldKnobAngle in
                // Calculate the total sweep of the arc (from 225° down to knobAngle)
                let sweepAngle = 225 - newKnobAngle
                // Define an approximate dash angle increment based on your dash style
                let dashAngleIncrement: Double = 10.3
                // Compute how many dashes have been rendered so far
                let newDashCount = Int(sweepAngle / dashAngleIncrement)
                
                let currentTime = Date()
                // Only trigger a haptic if the dash count has changed and if the minimum delay has passed
                if newDashCount != lastHapticStep && currentTime >= nextAvailableHapticTime {
                    let stepCount = abs(newDashCount - lastHapticStep)
                    let delayBetweenHaptics = 0.032  // seconds between each haptic event
                    
                    for i in 1...stepCount {
                        let scheduledTime = nextAvailableHapticTime.addingTimeInterval(delayBetweenHaptics * Double(i))
                        let dispatchDelay = scheduledTime.timeIntervalSince(currentTime)
                        DispatchQueue.main.asyncAfter(deadline: .now() + dispatchDelay) {
                            triggerHaptic()
                            withAnimation(.bouncy(duration: 0.01)) {
                                hapticHappened = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                                withAnimation(.bouncy(duration: 0.5)) {
                                    hapticHappened = false
                                }
                            }
                        }
                    }
                    // Update the next available haptic time to throttle further events
                    nextAvailableHapticTime = nextAvailableHapticTime.addingTimeInterval(delayBetweenHaptics * Double(stepCount))
                    lastHapticStep = newDashCount
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
    
    private func triggerHaptic() {
        feedbackGenerator.impactOccurred()
        withAnimation(.bouncy(duration: 0.01)) {
            hapticHappened = true
        }
        feedbackGenerator.prepare()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            withAnimation(.bouncy(duration: 0.5)) {
                hapticHappened = false
            }
        }
    }
}
