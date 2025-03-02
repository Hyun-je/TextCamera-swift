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
                        VStack(spacing: 0) {
                            ScrollView {
                                TextEditor(text: $textRecognizer.recognizedText)
                                    .frame(minHeight: geometry.size.height - 40) // 언어 표시 영역 고려
                                    .padding()
                                    .background(Color(UIColor.systemBackground))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                            }
                            .padding([.horizontal, .top])
                            
                            // Display selected language
                            Text("Language: \(textRecognizer.selectedLanguage.displayName)")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.vertical, 8)
                        }
                    }
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
                        .zIndex(1) // 토스트 메시지가 항상 위에 표시되도록
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

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
} 