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
        let ciImage = CIImage(image: image)!.oriented(CGImagePropertyOrientation(image.imageOrientation))
        let context = CIContext(options: nil)

        // Slice the image into vertical patches with overlap
        let patchWidth = ciImage.extent.width
        let patchHeight = ciImage.extent.height / 8
        let overlapHeight = patchHeight / 2
        let patchCount = Int(ceil((ciImage.extent.height - overlapHeight) / (patchHeight - overlapHeight)))

        var imagePatches: [CGImage] = []
        for i in 0..<patchCount {
            let cropRect = CGRect(x: 0, y: CGFloat(i) * (patchHeight - overlapHeight), width: patchWidth, height: patchHeight)
            let croppedImage = ciImage.cropped(to: cropRect)
            guard let cgImage = context.createCGImage(croppedImage, from: croppedImage.extent) else {
                isRecognizing = false
                completion("")
                return
            }
            imagePatches.append(cgImage)
        }

        // Save imagePatches to gallery
        #if 0
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        for (index, patch) in imagePatches.enumerated() {
            UIImageWriteToSavedPhotosAlbum(UIImage(cgImage: patch), nil, nil, nil)
        }
        #endif


        // Run text recognition on each image patch
        var allObservations: [VNRecognizedTextObservation] = []
        let group = DispatchGroup()
        
        for (index, patch) in imagePatches.enumerated() {
            group.enter()
            
            let requestHandler = VNImageRequestHandler(cgImage: patch, orientation: .up)
            let request = VNRecognizeTextRequest { [weak self] request, error in
                defer { group.leave() }
                
                guard error == nil,
                      let observations = request.results as? [VNRecognizedTextObservation] else {
                    return
                }
                
                // Adjust y coordinates based on patch index
                let adjustedObservations = observations.map { observation -> VNRecognizedTextObservation in
                    // Adjust y coordinate based on patch position
                    let yOffset = CGFloat(index) * (patchHeight - overlapHeight) / ciImage.extent.height
                    let adjustedBoundingBox = CGRect(
                        x: observation.boundingBox.origin.x,
                        y: observation.boundingBox.origin.y / 8 + CGFloat(yOffset),
                        width: observation.boundingBox.width,
                        height: observation.boundingBox.height / 8
                    )
                    let adjusted = VNRecognizedTextObservation(boundingBox: adjustedBoundingBox)
                    return adjusted
                }
                
                allObservations.append(contentsOf: adjustedObservations)
            }
            
            // Configure recognition language
            request.recognitionLanguages = [selectedLanguage.rawValue]
            request.recognitionLevel = .accurate
            
            do {
                try requestHandler.perform([request])
            } catch {
                print("Error performing text recognition: \(error)")
                group.leave()
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            
            // Sort observations by vertical position
            self.textObservations = allObservations.sorted {
                $0.boundingBox.origin.y > $1.boundingBox.origin.y
            }
            
            // Extract recognized text
            let recognizedStrings = self.textObservations.compactMap { observation -> String in
                guard let topCandidate = observation.topCandidates(1).first else { return "" }
                return topCandidate.string
            }
            
            self.recognizedText = recognizedStrings.joined(separator: "\n")
            self.isRecognizing = false
            completion(self.recognizedText)
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
