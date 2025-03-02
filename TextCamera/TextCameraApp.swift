//
//  TextCameraApp.swift
//  TextCamera
//
//  Created by Jaehyeon Park on 3/1/25.
//

import SwiftUI

@main
struct TextCameraApp: App {
    @StateObject private var textRecognizer = TextRecognizer()
    
    init() {
        // Add camera usage description
        if let infoDictionary = Bundle.main.infoDictionary, 
           infoDictionary["NSCameraUsageDescription"] == nil {
            print("Warning: NSCameraUsageDescription is not set in Info.plist.")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(textRecognizer)
        }
    }
}
