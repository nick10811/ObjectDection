//
//  Detection.swift
//  ObjectDetection
//
//  Created by Nick Yang on 2022/5/8.
//  Copyright © 2022 MachineThink. All rights reserved.
//

import CoreMedia
import CoreML
import UIKit
import Vision

protocol DetectionDelegate: class {
    func detection(_ detection: Detection, predictions: [VNRecognizedObjectObservation])
}

public class Detection {
    weak var delegate: DetectionDelegate?
    
    var currentBuffer: CVPixelBuffer?

    let coreMLModel = MobileNetV2_SSDLite()

    lazy var visionModel: VNCoreMLModel = {
      do {
        return try VNCoreMLModel(for: coreMLModel.model)
      } catch {
        fatalError("Failed to create VNCoreMLModel: \(error)")
      }
    }()

    lazy var visionRequest: VNCoreMLRequest = {
      let request = VNCoreMLRequest(model: visionModel, completionHandler: {
        [weak self] request, error in
        self?.processObservations(for: request, error: error)
      })

      // NOTE: If you use another crop/scale option, you must also change
      // how the BoundingBoxView objects get scaled when they are drawn.
      // Currently they assume the full input image is used.
      request.imageCropAndScaleOption = .scaleFill
      return request
    }()

    let maxBoundingBoxViews = 10
    var boundingBoxViews = [BoundingBoxView]()
    var colors: [String: UIColor] = [:]

    func predict(sampleBuffer: CMSampleBuffer) {
      if currentBuffer == nil, let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
        currentBuffer = pixelBuffer

        // Get additional info from the camera.
        var options: [VNImageOption : Any] = [:]
        if let cameraIntrinsicMatrix = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil) {
          options[.cameraIntrinsics] = cameraIntrinsicMatrix
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: options)
        do {
          try handler.perform([self.visionRequest])
        } catch {
          print("Failed to perform Vision request: \(error)")
        }

        currentBuffer = nil
      }
    }
    
    func processObservations(for request: VNRequest, error: Error?) {
    }
}
