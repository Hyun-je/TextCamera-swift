//
//  ContentView.swift
//  TextCamera
//
//  Created by Jaehyeon Park on 3/1/25.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @EnvironmentObject var textRecognizer: TextRecognizer
    @State private var capturedImage: UIImage?
    @State private var isShowingCamera = true
    @State private var cameraPermissionGranted = false
    @State private var showPermissionAlert = false
    
    var body: some View {
        ZStack {
            if isShowingCamera {
                if cameraPermissionGranted {
                    CameraView(capturedImage: $capturedImage, isShowingCamera: $isShowingCamera)
                        .environmentObject(textRecognizer)
                } else {
                    VStack {
                        Text("Camera permission required")
                            .font(.headline)
                            .padding()
                        
                        Button("Request Permission") {
                            checkCameraPermission()
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
            } else if let _ = capturedImage {
                ResultView(textRecognizer: textRecognizer, capturedImage: $capturedImage, isShowingCamera: $isShowingCamera)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            checkCameraPermission()
        }
        .alert("Camera Permission Required", isPresented: $showPermissionAlert) {
            Button("Go to Settings", role: .none) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraPermissionGranted = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    cameraPermissionGranted = granted
                    if !granted {
                        showPermissionAlert = true
                    }
                }
            }
        case .denied, .restricted:
            cameraPermissionGranted = false
            showPermissionAlert = true
        @unknown default:
            break
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(TextRecognizer())
}
