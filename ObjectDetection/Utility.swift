//
//  Utility.swift
//  ObjectDetection
//
//  Created by Nick Yang on 2022/5/7.
//  Copyright © 2022 MachineThink. All rights reserved.
//

import Foundation
import UIKit

@propertyWrapper
struct UseAutoLayout<T: UIView> {
    var wrappedValue: T {
        didSet { setAutoLayout() }
    }
    
    init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
        setAutoLayout()
    }
    
    func setAutoLayout() {
        wrappedValue.translatesAutoresizingMaskIntoConstraints = false
    }
}

public class Utility {
    static let recordFileName = "record.mp4"
    static let copiedFileName = "copied.mp4"
    
    static func getViewController(_ storyboardName: String, withIdentifier: String) -> UIViewController {
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: withIdentifier)
    }
    
    static func getLocalFilePath(_ name: String) -> URL {
        let fileManager = FileManager.default
        let url = fileManager.temporaryDirectory.appendingPathComponent(name)
        if fileManager.fileExists(atPath: url.path) {
            do {
                try fileManager.removeItem(at: url)
            } catch let error {
                debugPrint("File removing failed. \(error)")
            }
        }
        return url
    }
    
    static func copyFile(at: URL, to: URL) -> Bool {
        let fileManager = FileManager.default
        do {
            try fileManager.copyItem(at: at, to: to)
            return true
        } catch let error {
            debugPrint("copy file failed. \(error.localizedDescription)")
            return false
        }
    }
}
