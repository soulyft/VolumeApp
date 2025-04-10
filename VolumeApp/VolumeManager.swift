//
//  VolumeManager.swift
//  VolumeApp
//
//  Created by Corey Lofthus on 4/10/25.
//

import SwiftUI
import MediaPlayer
import AVFoundation

@Observable class VolumeManager {
    var volume: Double = 0.5
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
