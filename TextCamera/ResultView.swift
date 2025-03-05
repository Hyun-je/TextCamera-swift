import SwiftUI

struct ResultView: View {
    @ObservedObject var textRecognizer: TextRecognizer
    @Binding var capturedImage: UIImage?
    @Binding var isShowingCamera: Bool
    @State private var showShareSheet = false
    @State private var showCopiedToast = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if textRecognizer.isRecognizing {
                    Spacer()
                    ProgressView("Recognizing text...")
                        .progressViewStyle(CircularProgressViewStyle())
                    Spacer()
                } else {
                    GeometryReader { geometry in
                        ZStack {
                            if let image = capturedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .overlay(
                                        BoundingBoxOverlay(
                                            textRecognizer: textRecognizer,
                                            imageSize: image.size
                                        )
                                    )
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    
                    // Display selected language
                    Text("Language: \(textRecognizer.selectedLanguage.displayName)")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.vertical, 8)
                }
                
                if showCopiedToast {
                    Text("Copied to clipboard")
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation {
                                    showCopiedToast = false
                                }
                            }
                        }
                        .zIndex(1)
                }
            }
             .navigationTitle("Recognized Text")
             .navigationBarTitleDisplayMode(.inline)
             .toolbar {
                 ToolbarItem(placement: .navigationBarLeading) {
                     Button(action: {
                         capturedImage = nil
                         isShowingCamera = true
                     }) {
                         Image(systemName: "camera")
                             .foregroundColor(.blue)
                     }
                 }
                
                 ToolbarItem(placement: .navigationBarTrailing) {
                     Button(action: {
                         showShareSheet = true
                     }) {
                         Image(systemName: "square.and.arrow.up")
                             .foregroundColor(.blue)
                     }
                 }
                
                 ToolbarItem(placement: .navigationBarTrailing) {
                     Button(action: {
                         textRecognizer.copyToClipboard()
                         withAnimation {
                             showCopiedToast = true
                         }
                     }) {
                         Image(systemName: "doc.on.doc")
                             .foregroundColor(.blue)
                     }
                 }
             }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(activityItems: [textRecognizer.recognizedText])
            }
        }
        .onAppear {
            if let image = capturedImage {
                textRecognizer.recognizeText(from: image) { _ in
                    textRecognizer.copyToClipboard()
                    withAnimation {
                        showCopiedToast = true
                    }
                }
            }
        }
    }
}

struct BoundingBoxOverlay: View {
    let textRecognizer: TextRecognizer
    let imageSize: CGSize
    
    var body: some View {
        GeometryReader { geometry in
            ZStack{
                let scale = min(
                    geometry.size.width / imageSize.width,
                    geometry.size.height / imageSize.height
                )

                ForEach(0..<textRecognizer.textObservations.count, id: \.self) { index in
                    let observation = textRecognizer.textObservations[index]
                    let box = textRecognizer.boundingBox(for: observation, in: imageSize)
                    
                    
                    Rectangle()
                        .stroke(Color.blue, lineWidth: 1)
                        .frame(width: box.width * scale, height: box.height * scale)
                        .position(x: box.width * scale / 2 + box.minX * scale, y: -box.height * scale / 2 + box.minY * scale)
                }
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
} 
