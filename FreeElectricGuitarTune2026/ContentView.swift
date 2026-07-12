//
//  ContentView.swift
//  FreeElectricGuitarTune2026
//
//  Created by Michael Vierfuß on 12.07.26.
//

import SwiftUI

struct ContentView: View {
    @State private var tuner = TunerViewModel()
    
    var body: some View {
        VStack(spacing: 40) {
            
            // Überschrift für die Buttons
            Text(tuner.selectedString == nil ? "Auto Detection Mode" : "Manual Target Mode")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.top, 20)
            
            // 1. Interaktive Saiten-Anzeige oben (EADGBE)
            HStack(spacing: 20) {
                ForEach(tuner.guitarStrings, id: \.name) { stringInfo in
                    Button(action: {
                        tuner.selectStringAction(stringInfo.name)
                    }) {
                        Text(stringInfo.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            // Wenn ausgewählt: grün. Wenn im Auto-Modus getroffen: grün. Sonst grau.
                            .foregroundColor(isHighlighted(stringName: stringInfo.name) ? .green : .gray)
                            .frame(width: 45, height: 45)
                            .background(
                                Circle()
                                    .fill(tuner.selectedString == stringInfo.name ? Color.green.opacity(0.2) : Color.clear)
                            )
                            .overlay(
                                Circle()
                                    .stroke(isHighlighted(stringName: stringInfo.name) ? Color.green : Color.gray.opacity(0.3), lineWidth: 2)
                            )
                    }
                }
            }
            
            Spacer()
            
            // 2. Erkanntes Ergebnis
            VStack(spacing: 10) {
                Text(tuner.closestNote)
                    .font(.system(size: 90, weight: .black, design: .rounded))
                    .foregroundColor(tuner.instruction == "In Tune!" ? .green : .white)
                
                Text(String(format: "%.1f Hz", tuner.currentFrequency))
                    .font(.title3)
                    .foregroundColor(.gray)
            }
            
            // 3. Stimm-Balken mit dem Punkt in der Mitte
            VStack(spacing: 10) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.3) )
                            .frame(height: 12)
                        
                        // Center-Punkt
                        Circle()
                            .fill(Color.white.opacity(0.6))
                            .frame(width: 16, height: 16)
                            .position(x: geometry.size.width / 2, y: 6)
                        
                        // Dynamischer Zeiger-Punkt
                        Circle()
                            .fill(tuner.instruction == "In Tune!" ? Color.green : Color.red)
                            .frame(width: 24, height: 24)
                            .position(
                                x: (geometry.size.width / 2) + (CGFloat(tuner.deviation) * (geometry.size.width - 30)),
                                y: 6
                            )
                            .animation(.easeOut(duration: 0.1), value: tuner.deviation)
                    }
                }
                .frame(height: 25)
                .padding(.horizontal, 30)
            }
            
            // 4. Richtungsanweisung (Tune UP / DOWN)
            Text(tuner.instruction)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(tuner.instruction == "In Tune!" ? .green : .orange)
            
            Spacer()
            
            Text("Tap a string above to lock it, tap again for Auto-Mode.\nStandard Tuning (A = 440Hz)")
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .preferredColorScheme(.dark)
    }
    
    // Hilfsfunktion zur visuellen Hervorhebung der Buttons
    private func isHighlighted(stringName: String) -> Bool {
        if tuner.selectedString == stringName {
            return true
        }
        // Im Automodus vergleichen wir die getroffene Note (Großbuchstabe)
        if tuner.selectedString == nil && tuner.closestNote == stringName.uppercased() {
            return true
        }
        return false
    }
}
