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
    static let fileName = "record.mov"
    
    static func getViewController(_ storyboardName: String, withIdentifier: String) -> UIViewController {
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: withIdentifier)
    }
}
