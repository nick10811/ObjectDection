//
//  MenuViewController.swift
//  ObjectDetection
//
//  Created by Nick Yang on 2022/5/7.
//  Copyright © 2022 MachineThink. All rights reserved.
//

import UIKit
import AVKit
import PhotosUI
import Vision

class MenuViewController: UIViewController {
    let recorder = VideoRecorder()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUp()
        recorder.delegate = self
    }
    
    func setUp() {
        // make buttons
        let detectButton = makeButton("Detect")
        detectButton.addTarget(self, action: #selector(detectPerson(_:)), for: .touchUpInside)
        let chooseButton = makeButton("Choose a Video")
        chooseButton.addTarget(self, action: #selector(chooseVideo(_:)), for: .touchUpInside)
        let playButton = makeButton("Play Latest Record Video")
        playButton.addTarget(self, action: #selector(playRecord(_:)), for: .touchUpInside)
        
        @UseAutoLayout var stackView = UIStackView(arrangedSubviews: [detectButton, chooseButton, playButton])
        stackView.distribution = .fillEqually
        stackView.axis = .vertical
        stackView.spacing = 30
        self.view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.widthAnchor.constraint(equalToConstant: 200),
            stackView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            stackView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 100)
        ])
    }
    
    func makeButton(_ title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.blue, for: .normal)
        button.frame.size = CGSize(width: 100, height: 40)
        return button
    }
    
    @objc func detectPerson(_ sender: UIButton) {
        guard let vc = Utility.getViewController("Main", withIdentifier: "DetectionViewController") as? DetectionViewController else { return }
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func chooseVideo(_ sender: UIButton) {
        var config = PHPickerConfiguration()
        config.filter = .videos
        let pickerController = PHPickerViewController(configuration: config)
        pickerController.delegate = self
        self.present(pickerController, animated: true, completion: nil)
        
    }
    
    // MARK: - test purpose
    @objc func playRecord(_ sender: UIButton) {
        let filePath = FileManager.default.temporaryDirectory.appendingPathComponent(Utility.recordFileName)
        playVideo(filePath)
    }
    
    private func playVideo(_ url: URL) {
        print("video's url: \(url.path)")
        let vc = AVPlayerViewController()
        vc.player = AVPlayer(url: url)
        self.present(vc, animated: true)
    }
    
}

// MARK:- PHPickerViewControllerDelegate
extension MenuViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)
        
        guard let provider = results.first?.itemProvider else { return }
        guard provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) else { return }
        provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] (url, error) in
            if let url = url {
                // copy to the local
                let desitnation = Utility.getLocalFilePath(Utility.copiedFileName)
                if Utility.copyFile(at: url, to: desitnation) {
                    self?.recorder.read(desitnation)
                    
                    // make sure the video can be palyed
//                    DispatchQueue.main.async {
//                        self?.playVideo(desitnation)
//                    }
                }
            }
        }
    }
}

extension MenuViewController: VideoRecorderDelegate {
    func videoRecorder(_ recorder: VideoRecorder, completion: (() -> ())?) {
        DispatchQueue.main.async {
            let alertVC = UIAlertController(title: "Alert", message: "The process is completed", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertVC.addAction(okAction)
            self.present(alertVC, animated: true)
        }
    }
}
