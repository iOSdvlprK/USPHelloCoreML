//
//  ContentView.swift
//  USPHelloCoreML
//
//  Created by joe on 10/22/25.
//

import SwiftUI
import CoreML
import PhotosUI
import Vision

struct Observation {
    let label: String
    let confidence: VNConfidence
    let boundingBox: CGRect
}

struct ContentView: View {
    @State private var probs: [String: Double] = [:]
    @State private var uiImage: UIImage? = UIImage(named: "stop-sign")
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var isCameraSelected: Bool = false
    
    let model = try! YOLOv3Tiny(configuration: MLModelConfiguration())
    @State private var detectedObjects: [Observation] = []
    
    var body: some View {
        VStack {
            Image(uiImage: uiImage!)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 300, height: 300)
                
            HStack {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                   Text("Select a Photo")
                }
                
                Button("Camera") {
                    isCameraSelected = true
                }.buttonStyle(.bordered)
            }
            
            Button("Predict") {
                let mlModel = model.model
                guard let coreMLModel = try? VNCoreMLModel(for: mlModel) else { return }
                
                let request = VNCoreMLRequest(model: coreMLModel) { request, error in
                    guard let results = request.results as? [VNRecognizedObjectObservation] else { return }
                    
                    detectedObjects = results.map { result in
                        guard let label = result.labels.first?.identifier else { return Observation(label: "", confidence: VNConfidence.zero, boundingBox: .zero) }
                        let confidence = result.labels.first?.confidence ?? 0.0
                        let boundingBox = result.boundingBox
                        let observation = Observation(label: label, confidence: confidence, boundingBox: boundingBox)
                        print(label)
                        print("\(confidence)")
                        print(boundingBox)
                        return observation
                    }
                }
                
                guard let image = uiImage, let pixelBuffer = image.toCVPixelBuffer() else { return }
                
                let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
                
                do {
                    try requestHandler.perform([request])
                } catch {
                    print(error.localizedDescription)
                }
            }.buttonStyle(.borderedProminent)
            
            ObservationListView(observations: detectedObjects)
        }
        .onChange(of: selectedPhotoItem) { _, selectedPhotoItem in
            selectedPhotoItem?.loadTransferable(type: Data.self, completionHandler: { result in
                print(result)
                switch result {
                    case .success(let data):
                        if let data {
                            uiImage = UIImage(data: data)
                        }
                    case .failure(let error):
                        print(error.localizedDescription)
                }
            })
        }
        .sheet(isPresented: $isCameraSelected, content: {
            ImagePicker(image: $uiImage, sourceType: .camera)
        })
        .padding()
    }
}

#Preview {
    ContentView()
}
