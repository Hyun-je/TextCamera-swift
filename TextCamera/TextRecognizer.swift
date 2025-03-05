import SwiftUI
import Vision
import VisionKit

class TextRecognizer: ObservableObject {
    @Published var recognizedText = ""
    @Published var isRecognizing = false
    @Published var selectedLanguage: RecognitionLanguage = .english
    @Published var textObservations: [VNRecognizedTextObservation] = []
    
    enum RecognitionLanguage: String, CaseIterable, Identifiable {
        case english = "en-US"
        case korean = "ko-KR"
        case japanese = "ja-JP"
        case chinese = "zh-Hans"
        case spanish = "es-ES"
        case french = "fr-FR"
        case german = "de-DE"
        
        var id: String { self.rawValue }
        
        var displayName: String {
            switch self {
            case .english: return "English"
            case .korean: return "Korean"
            case .japanese: return "Japanese"
            case .chinese: return "Chinese (Simplified)"
            case .spanish: return "Spanish"
            case .french: return "French"
            case .german: return "German"
            }
        }
    }
    
    func recognizeText(from image: UIImage, completion: @escaping (String) -> Void) {
        isRecognizing = true

        // Create CGImage with correct orientation
        let ciImage = CIImage(image: image)!
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            isRecognizing = false
            completion("")
            return
        }

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, orientation: CGImagePropertyOrientation(image.imageOrientation), options: [:])
        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Text recognition error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isRecognizing = false
                    completion("")
                }
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                DispatchQueue.main.async {
                    self.isRecognizing = false
                    completion("")
                }
                return
            }
            
            let recognizedText = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: "\n")

            DispatchQueue.main.async {
                self.textObservations = observations
                self.recognizedText = recognizedText
                self.isRecognizing = false
                completion(recognizedText)
            }
        }
        
        // Set high accuracy
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        // Set recognition language
        request.recognitionLanguages = [selectedLanguage.rawValue]
        
        do {
            try requestHandler.perform([request])
        } catch {
            print("Text recognition request error: \(error.localizedDescription)")
            isRecognizing = false
            completion("")
        }
    }
    
    func boundingBox(for observation: VNRecognizedTextObservation, in imageSize: CGSize) -> CGRect {
        // Vision's coordinate system is normalized (0,0 is bottom-left) and needs to be converted to UIKit's coordinate system (0,0 is top-left)
        let boundingBox = observation.boundingBox
        
        
        return CGRect(
            x: boundingBox.origin.x * imageSize.width,
            y: (1 - boundingBox.origin.y) * imageSize.height,
            width: boundingBox.width * imageSize.width,
            height: boundingBox.height * imageSize.height
        )
    }
    
    func copyToClipboard() {
        UIPasteboard.general.string = recognizedText
    }
} 


extension CGImagePropertyOrientation {
    init(_ uiImageOrientation: UIImage.Orientation) {
        switch uiImageOrientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        default: self = .up
        }
    }
}
