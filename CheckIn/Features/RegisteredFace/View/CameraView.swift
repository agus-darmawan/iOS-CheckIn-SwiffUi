//
//  CameraView.swift
//  CheckIn
//
//  Created by Darmawan on 25/06/25.
//

import SwiftUI
import AVFoundation

struct CameraView: UIViewControllerRepresentable {
    var completion: (UIImage) -> Void
    
    static var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraDevice = .front
        picker.delegate = context.coordinator
        picker.cameraCaptureMode = .photo
        picker.showsCameraControls = true
        picker.cameraOverlayView = createCameraOverlay()
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }
    
    private func createCameraOverlay() -> UIView {
        let overlayView = UIView(frame: UIScreen.main.bounds)
        overlayView.backgroundColor = UIColor.clear
        
        // Add face guide
        let guideSize = CGSize(width: 200, height: 250)
        let guideView = UIView(frame: CGRect(
            origin: CGPoint(
                x: (overlayView.bounds.width - guideSize.width) / 2,
                y: (overlayView.bounds.height - guideSize.height) / 2
            ),
            size: guideSize
        ))
        
        guideView.backgroundColor = UIColor.clear
        guideView.layer.borderColor = UIColor.yellow.cgColor
        guideView.layer.borderWidth = 2.0
        guideView.layer.cornerRadius = 10
        guideView.alpha = 0.6
        
        overlayView.addSubview(guideView)
        overlayView.isUserInteractionEnabled = false
        
        return overlayView
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var completion: (UIImage) -> Void
        
        init(completion: @escaping (UIImage) -> Void) {
            self.completion = completion
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                completion(image.fixedOrientation())
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
