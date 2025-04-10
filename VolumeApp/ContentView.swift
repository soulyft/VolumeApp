//
//  ContentView.swift
//  VolumeApp
//
//  Created by Corey Lofthus on 2/17/25.
//

import SwiftUI
import MediaPlayer
import AVFoundation



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



struct ContentView: View {
    @State private var volumeManager = VolumeManager()
    
    var body: some View {
        VStack(spacing: 40) {
            ZStack{
                Text("\(Int(volumeManager.volume * 100))%")
                    .contentTransition(.numericText())
                    .font(.largeTitle)
                   
                    .fontWeight(.black)
                    .fontDesign(.rounded)

                Text("\(Int(volumeManager.volume * 100))%")
                    .font(.largeTitle)
                    .contentTransition(.numericText())
                    .fontWeight(.black)
                    .fontDesign(.rounded)
                    .foregroundStyle(.thinMaterial.opacity(0.8))
                    .blur(radius: 2)
            }
            
            Spacer()
            
            ThreeQuarterVolumeKnob(volume: $volumeManager.volume)
                .frame(width: 240, height: 240)

            
            Spacer()
        }
        .padding()
    }
}


#Preview {
    ContentView()
}
