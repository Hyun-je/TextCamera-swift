import SwiftUI
import AVFoundation
import UIKit

struct CameraView: View {
    @StateObject private var viewModel = CameraViewModel()
    @Binding var capturedImage: UIImage?
    @Binding var isShowingCamera: Bool
    @State private var showLanguageMenu = false
    @EnvironmentObject var textRecognizer: TextRecognizer
    
    var body: some View {
        ZStack {
            CameraPreviewView(session: viewModel.session)
                .ignoresSafeArea()
                .onAppear {
                    viewModel.checkCameraPermission()
                }
                .onDisappear {
                    viewModel.stopSession()
                }
            
            VStack {
                HStack {
                    Spacer()
                    
                    Button(action: {
                        showLanguageMenu.toggle()
                    }) {
                        HStack {
                            Text(textRecognizer.selectedLanguage.displayName)
                                .foregroundColor(.white)
                            Image(systemName: "chevron.down")
                                .foregroundColor(.white)
                        }
                        .padding(8)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(8)
                    }
                    .padding(.top, 50)
                    .padding(.trailing, 20)
                }
                
                Spacer()
                
                HStack {
                    ZStack {
                        Button(action: {
                            viewModel.toggleCameraType()
                        }) {
                            Image(systemName: "camera")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .disabled(viewModel.availableCameraTypes.count <= 1)
                        .opacity(viewModel.availableCameraTypes.count > 1 ? 1.0 : 0.5)
                        
                        // 카메라 배율 표시를 별도의 뷰로 분리
                        if viewModel.availableCameraTypes.count > 1 {
                            Text(viewModel.currentCameraType.shortName)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(10)
                                .offset(x: 0, y: 35)
                        }
                    }
                    .padding(.leading, 30)
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.capturePhoto { image in
                            if let image = image {
                                capturedImage = image
                                isShowingCamera = false
                            }
                        }
                    }) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Circle()
                                    .stroke(Color.black.opacity(0.2), lineWidth: 2)
                                    .frame(width: 70, height: 70)
                            )
                    }
                    
                    Spacer()
                }
                .padding(.bottom, 30)
            }
        }
        .alert("Camera Permission Required", isPresented: $viewModel.showPermissionAlert) {
            Button("Go to Settings", role: .none) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .actionSheet(isPresented: $showLanguageMenu) {
            ActionSheet(
                title: Text("Select Recognition Language"),
                buttons: languageButtons()
            )
        }
    }
    
    private func languageButtons() -> [ActionSheet.Button] {
        var buttons = TextRecognizer.RecognitionLanguage.allCases.map { language in
            ActionSheet.Button.default(Text(language.displayName)) {
                textRecognizer.selectedLanguage = language
            }
        }
        buttons.append(.cancel())
        return buttons
    }
}

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.frame
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

enum CameraType: CaseIterable {
    case ultraWideAngle
    case wideAngle
    case telephoto
    
    var deviceType: AVCaptureDevice.DeviceType {
        switch self {
        case .ultraWideAngle:
            return .builtInUltraWideCamera
        case .wideAngle:
            return .builtInWideAngleCamera
        case .telephoto:
            return .builtInTelephotoCamera
        }
    }
    
    var displayName: String {
        switch self {
        case .ultraWideAngle:
            return "초광각"
        case .wideAngle:
            return "광각"
        case .telephoto:
            return "망원"
        }
    }
    
    var shortName: String {
        switch self {
        case .ultraWideAngle:
            return "0.5x"
        case .wideAngle:
            return "1x"
        case .telephoto:
            return "2x"
        }
    }
    
    // FOV 순서대로 정렬하기 위한 값 (넓은 FOV가 작은 값)
    var fovOrder: Int {
        switch self {
        case .ultraWideAngle:
            return 0  // 가장 넓은 FOV
        case .wideAngle:
            return 1  // 중간 FOV
        case .telephoto:
            return 2  // 가장 좁은 FOV
        }
    }
}

class CameraViewModel: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var showPermissionAlert = false
    @Published var currentCameraType: CameraType = .wideAngle
    @Published var availableCameraTypes: [CameraType] = []
    
    private let photoOutput = AVCapturePhotoOutput()
    private var completionHandler: ((UIImage?) -> Void)?
    private var currentInput: AVCaptureDeviceInput?
    
    func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCaptureSession()
            checkAvailableCameras()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupCaptureSession()
                        self?.checkAvailableCameras()
                    } else {
                        self?.showPermissionAlert = true
                    }
                }
            }
        case .denied, .restricted:
            showPermissionAlert = true
        @unknown default:
            break
        }
    }
    
    private func checkAvailableCameras() {
        var cameras: [CameraType] = []
        
        // 모든 가능한 카메라 타입 확인
        if AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) != nil {
            cameras.append(.ultraWideAngle)
        }
        
        // 광각 카메라는 기본적으로 모든 기기에 있음
        cameras.append(.wideAngle)
        
        if AVCaptureDevice.default(.builtInTelephotoCamera, for: .video, position: .back) != nil {
            cameras.append(.telephoto)
        }
        
        // FOV 순서대로 정렬 (넓은 FOV부터)
        availableCameraTypes = cameras.sorted { $0.fovOrder < $1.fovOrder }
    }
    
    func setupCaptureSession() {
        session.beginConfiguration()
        
        if let currentInput = currentInput {
            session.removeInput(currentInput)
        }
        
        guard let videoDevice = AVCaptureDevice.default(currentCameraType.deviceType, for: .video, position: .back),
              let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
              session.canAddInput(videoDeviceInput) else {
            // 선택한 카메라를 사용할 수 없는 경우 광각 카메라로 폴백
            if currentCameraType != .wideAngle {
                currentCameraType = .wideAngle
                session.commitConfiguration()
                setupCaptureSession()
                return
            }
            return
        }
        
        session.addInput(videoDeviceInput)
        currentInput = videoDeviceInput
        
        // 고해상도 촬영 활성화
        if session.canAddOutput(photoOutput) {
            photoOutput.isHighResolutionCaptureEnabled = true
            session.addOutput(photoOutput)
        }
        
        session.commitConfiguration()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }
    
    func toggleCameraType() {
        guard availableCameraTypes.count > 1 else { return }
        
        // 현재 카메라 타입의 인덱스 찾기
        if let currentIndex = availableCameraTypes.firstIndex(where: { $0 == currentCameraType }) {
            // 다음 카메라 타입으로 전환 (순환)
            let nextIndex = (currentIndex + 1) % availableCameraTypes.count
            currentCameraType = availableCameraTypes[nextIndex]
            
            session.stopRunning()
            setupCaptureSession()
        }
    }
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        guard session.isRunning else { return }
        
        self.completionHandler = completion
        
        let settings = AVCapturePhotoSettings()
        settings.isHighResolutionPhotoEnabled = true
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func stopSession() {
        session.stopRunning()
    }
}

extension CameraViewModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Photo capture error: \(error.localizedDescription)")
            completionHandler?(nil)
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            completionHandler?(nil)
            return
        }
        
        completionHandler?(image)
    }
} 