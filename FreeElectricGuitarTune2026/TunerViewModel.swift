//
//  TunerViewModel.swift
//  FreeElectricGuitarTune2026
//
//  Created by Michael Vierfuß on 12.07.26.
//

import Foundation
import AVFoundation
import Accelerate
import Observation

@Observable
final class TunerViewModel {
    var currentFrequency: Float = 0.0
    var closestNote: String = "-"
    var deviation: Float = 0.0
    var instruction: String = "Play a string"
    
    // Die aktuell manuell ausgewählte Saite (nil bedeutet: Automatischer Modus)
    var selectedString: String? = nil
    
    // Die exakten Frequenzen der Gitarrensaiten basierend auf A4 = 440Hz
    let guitarStrings = [
        (name: "E", freq: 82.41),
        (name: "A", freq: 110.00),
        (name: "D", freq: 146.83),
        (name: "G", freq: 196.00),
        (name: "B", freq: 246.94),
        // Wir nennen die hohe E-Saite zur Unterscheidung im UI "e", erkennen aber das "E"
        (name: "e", freq: 329.63)
    ]
    
    private let audioEngine = AVAudioEngine()
    private let bufferSize: AVAudioFrameCount = 8192
    private let allNotes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    
    init() {
        setupAudio()
    }
    
    func setupAudio() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
        try? session.setActive(true)
        
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.inputFormat(forBus: 0)
        
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: inputFormat) { [weak self] buffer, time in
            self?.analyzeAudio(buffer: buffer)
        }
        
        try? audioEngine.start()
    }
    
    private func analyzeAudio(buffer: AVAudioPCMBuffer) {
        guard let channels = buffer.floatChannelData else { return }
        let channelData = channels[0]
        let frameCount = Int(buffer.frameLength)
        let sampleRate = Float(buffer.format.sampleRate)
        
        var rms: Float = 0
        vDSP_rmsqv(channelData, 1, &rms, vDSP_Length(frameCount))
        
        guard rms > 0.005 else { return }
        
        let minPeriod = Int(sampleRate / 450.0)
        let maxPeriod = Int(sampleRate / 65.0)
        
        var bestPeriod = 0
        var maxCorrelation: Float = -Float.infinity
        
        for period in minPeriod...maxPeriod {
            var correlation: Float = 0
            vDSP_dotpr(channelData, 1, channelData + period, 1, &correlation, vDSP_Length(frameCount - period))
            
            if correlation > maxCorrelation {
                maxCorrelation = correlation
                bestPeriod = period
            }
        }
        
        guard bestPeriod > 0 else { return }
        let frequency = sampleRate / Float(bestPeriod)
        
        if frequency >= 70.0 && frequency <= 400.0 {
            DispatchQueue.main.async { [weak self] in
                self?.updateTuner(with: frequency)
            }
        }
    }
    
    private func updateTuner(with frequency: Float) {
        self.currentFrequency = frequency
        
        // Falls der Nutzer manuell eine Saite fixiert hat:
        if let targetString = selectedString,
           let targetInfo = guitarStrings.first(where: { $0.name == targetString }) {
            
            self.closestNote = targetInfo.name.uppercased()
            
            // Frequenz-Abweichung in Halbtönen (Cents) zur Ziel-Saite berechnen
            let targetFrequency = Float(targetInfo.freq)
            let noteNumDifference = 12 * log2(frequency / targetFrequency)
            
            // Begrenzen auf den Balkenbereich (-0.5 bis +0.5)
            self.deviation = max(-0.5, min(0.5, noteNumDifference))
            
            updateInstruction(diff: noteNumDifference)
            
        } else {
            // AUTOMATISCHER MODUS (wie vorher)
            let noteNum = 12 * log2(frequency / 440.0) + 69
            let roundedNoteNum = Int(round(noteNum))
            
            let noteIndex = (roundedNoteNum % 12 + 12) % 12
            self.closestNote = allNotes[noteIndex]
            
            let diff = noteNum - Float(roundedNoteNum)
            self.deviation = diff
            
            updateInstruction(diff: diff)
        }
    }
    
    private func updateInstruction(diff: Float) {
        if abs(diff) < 0.02 {
            self.instruction = "In Tune!"
        } else if diff < 0 {
            self.instruction = "Tune UP ⬆️"
        } else {
            self.instruction = "Tune DOWN ⬇️"
        }
    }
    
    // Funktion zum Umschalten, wenn eine Saite im UI geklickt wird
    func selectStringAction(_ stringName: String) {
        if selectedString == stringName {
            selectedString = nil // Abwählen -> wieder automatisch
        } else {
            selectedString = stringName // Saite fixieren
        }
    }
}
