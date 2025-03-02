import SwiftUI
import Vision
import VisionKit

class TextRecognizer: ObservableObject {
    @Published var recognizedText = ""
    @Published var isRecognizing = false
    @Published var selectedLanguage: RecognitionLanguage = .english
    
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
        
        guard let cgImage = image.cgImage else {
            isRecognizing = false
            completion("")
            return
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
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
    
    func copyToClipboard() {
        UIPasteboard.general.string = recognizedText
    }
} 