//
//  PersonDetection.swift
//  ObjectDetection
//
//  Created by Nick Yang on 2022/5/8.
//  Copyright © 2022 MachineThink. All rights reserved.
//

import CoreMedia
import CoreML
import UIKit
import Vision

public class PersonDetection: Detection {
    override func processObservations(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            if let results = request.results as? [VNRecognizedObjectObservation] {
                let personResults = results.filter({ $0.labels[0].identifier == "person" })
                self.delegate?.detection(self, predictions: personResults)
            } else {
                self.delegate?.detection(self, predictions: [])
            }
        }
    }
}
