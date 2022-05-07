//
//  PhotoLibraryHelper.swift
//  ObjectDetection
//
//  Created by Nick Yang on 2022/5/7.
//  Copyright © 2022 MachineThink. All rights reserved.
//

import Foundation
import Photos

public class PhotoLibraryHelper {
    func grant(completion: @escaping (Bool) -> Void) {
        // permission
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        if status == .notDetermined || status == .denied {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { auth in
                if auth == .authorized {
                    completion(true)
                } else {
                    print("user denied access the photo library.")
                    completion(false)
                }
            }
        } else {
            completion(true)
        }
    }
    
    func save(_ fileURL: URL) {
        grant { auth in
            if auth {
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
                }, completionHandler: nil)
            }
        }
    }
    
}
