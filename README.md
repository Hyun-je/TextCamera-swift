# TextCamera

TextCamera is an iOS app that recognizes text from camera-captured images and provides it in an editable format.

![Icon](https://github.com/user-attachments/assets/b74ad0e5-696a-4f91-a2c3-74ea79958251)

## Key Features

- Full-screen camera live preview
- Multiple camera lens support (Ultra-wide, Wide, Telephoto) on compatible devices
- Language selection for text recognition
- Immediate text recognition after taking a photo (using Vision framework)
- Automatic clipboard copying of recognized text
- Text editing and sharing functionality
- Re-capture option

## How to Use

1. When you launch the app, the camera screen is displayed.
2. Tap the camera icon in the bottom left to switch between available camera lenses (0.5x, 1x, 2x).
3. Tap the language selector in the top right to choose the recognition language.
4. Tap the round button at the bottom center to take a photo.
5. Text is automatically recognized from the captured image and the result screen appears.
6. The recognized text is automatically copied to the clipboard.
7. Tap the camera button in the top left to take another photo.
8. Tap the share button in the top right to share the text.

## Camera Features

- **Multiple Lens Support**: Switch between ultra-wide (0.5x), wide (1x), and telephoto (2x) lenses if your device supports them.
- **Lens Indicator**: The current lens selection is displayed below the camera selection button.
- **Automatic Availability Detection**: The app automatically detects which lenses are available on your device.

## Text Recognition

- **Multi-language Support**: Select from various languages for text recognition.
- **Optimized Recognition**: The app uses Apple's Vision framework for accurate text detection.

## Requirements

- iOS 15.0 or later
- Camera access permission

## Development Environment

- Swift 5.9
- SwiftUI
- Vision framework
- AVFoundation framework
- Xcode 15.0 or later 

## Note

All code in this project was written with the assistance of AI (Claude 3.7 Sonnet). The AI helped with designing the app architecture, implementing the camera functionality, text recognition features, and UI components. 
