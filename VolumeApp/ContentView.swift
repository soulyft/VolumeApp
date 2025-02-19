//
//  ContentView.swift
//  VolumeApp
//
//  Created by Corey Lofthus on 2/17/25.
//

import SwiftUI
import MediaPlayer
import AVFoundation

// MARK: - Volume Manager

class VolumeManager: ObservableObject {
    @Published var volume: Double = 0.5
    private var volumeObservation: NSKeyValueObservation?
    
    init() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            // Keep the session active so we can detect hardware volume changes.
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true, options: [])
        } catch {
            print("Error activating audio session: \(error)")
        }
        // NOTE: outputVolume might only update if audio is actually playing.
        volume = Double(audioSession.outputVolume)
        
        volumeObservation = audioSession.observe(\.outputVolume, options: [.new]) { [weak self] session, change in
            if let newVol = change.newValue {
                DispatchQueue.main.async {
                    self?.volume = Double(newVol)
                }
            }
        }
    }
    
    deinit {
        volumeObservation?.invalidate()
    }
}

// MARK: - MPVolumeView Helper

struct HiddenVolumeView: UIViewRepresentable {
    func makeUIView(context: Context) -> MPVolumeView {
        let volumeView = MPVolumeView(frame: .zero)
//        volumeView.showsRouteButton = false
        volumeView.showsVolumeSlider = true
        return volumeView
    }
    func updateUIView(_ uiView: MPVolumeView, context: Context) {}
}

/// Sets the system volume using MPVolumeView (workaround approach).
func setSystemVolume(_ value: Double) {
    let volumeView = MPVolumeView(frame: .zero)
    if let slider = volumeView.subviews.compactMap({ $0 as? UISlider }).first {
        // A small delay helps ensure the slider is ready.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            slider.value = Float(value)
        }
    }
}

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
}

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

// MARK: - Main Content View

struct ContentView: View {
    @StateObject private var volumeManager = VolumeManager()
    
    var body: some View {
        VStack(spacing: 40) {
            ZStack{
                Text("\(Int(volumeManager.volume * 100))%")
                    .font(.largeTitle)
                   
                    .fontWeight(.black)
                    .fontDesign(.rounded)
                Text("\(Int(volumeManager.volume * 100))%")
                    .font(.largeTitle)
                   
                    .fontWeight(.black)
                    .fontDesign(.rounded)
                    .foregroundStyle(.thinMaterial.opacity(0.8))
                    .blur(radius: 2)
            }

            Spacer()
            ZStack{
                ThreeQuarterVolumeKnob(volume: $volumeManager.volume)
                    .frame(width: 240, height: 240)
            }
            Spacer()
        }
        .padding()
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
