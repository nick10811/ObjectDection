//
//  ReadWriteVideo.swift
//  ObjectDetection
//
//  Created by Nick Yang on 2022/5/8.
//  Copyright © 2022 MachineThink. All rights reserved.
//

import AVKit
import AVFoundation
import Vision

protocol VideoRecorderDelegate: class {
    func videoRecorder(_ recorder: VideoRecorder, completion: (() -> ())?)
}

public class VideoRecorder {
    enum Constant {
        static let outputSettings: [String: Any] = [
            AVVideoCodecKey : AVVideoCodecType.h264,
            AVVideoWidthKey : 720,
            AVVideoHeightKey : 1280,
            AVVideoCompressionPropertiesKey : [
                // FIXME: what's the suitable value?
                AVVideoAverageBitRateKey : 2300000
            ]
        ]
    }
    
    let detection: PersonDetection!
    weak var delegate: VideoRecorderDelegate?
    
    var videoWritter: AVAssetWriter!
    lazy var videoWritterInput = AVAssetWriterInput(mediaType: .video, outputSettings: Constant.outputSettings)
    
    let duration: CGFloat = 10 // 10s
    var recordsPath: URL?
    var isRecording = false
    var sessionAtSourceTime: CMTime?
    var isWritable: Bool {
        return isRecording && videoWritter != nil && videoWritter.status == .writing
    }
    
    init() {
        detection = PersonDetection()
        detection.delegate = self
    }
    
    func read(_ fileURL: URL) {
        guard let videoReader = try? AVAssetReader(asset: AVAsset(url: fileURL)) else { return }
        
        print("track count: \(videoReader.asset.tracks.count)")
        guard let track = videoReader.asset.tracks(withMediaType: .video).first else { return }
        
        let videoReaderOutput = AVAssetReaderTrackOutput(track: track, outputSettings: nil)
        
        if videoReader.canAdd(videoReaderOutput) {
            videoReader.add(videoReaderOutput)
        }
        videoReader.startReading()
        
        while videoReader.status == .reading {
            print("reading")
            // retrive CMSampleBuffer and pass it into PersonDetection
            // FIXME: how many frames in 1 second?
            if let sampleBuffer = videoReaderOutput.copyNextSampleBuffer() {
                if isWritable, sessionAtSourceTime == nil {
                    print("start writting")
                    sessionAtSourceTime = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer)
                    videoWritter.startSession(atSourceTime: sessionAtSourceTime!)
                    DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
                        self?.stopRecord()
                    }
                }
                
                if isWritable, videoWritterInput.isReadyForMoreMediaData {
                    videoWritterInput.append(sampleBuffer)
                }
                
                detection.predict(sampleBuffer: sampleBuffer)
            }
        }
        
        if videoReader.status == .completed {
            print("complete reading")
        }
    }
    
    func startRecord() {
        guard !isRecording else { return }
        isRecording = true
        sessionAtSourceTime = nil
        setUpWritter()
        
        switch videoWritter.status {
        case .writing  : print("writter status: writing")
        case .completed: print("writter status: completed")
        case .failed   : print("writter status: failed")
        case .cancelled: print("writter status: canceled")
        default        : print("writter status: unknown")
        }
    }
    
    func stopRecord() {
        guard isRecording else { return }
        isRecording = false
        videoWritterInput.markAsFinished()
        videoWritter.finishWriting { [weak self] in
            guard let self = self else { return }
            self.sessionAtSourceTime = nil
            if let url = self.recordsPath {
                let photo = PhotoLibraryHelper()
                photo.save(url)
                self.delegate?.videoRecorder(self, completion: nil)
            }
        }
        print("complete writing")
    }
    
    private func setUpWritter() {
        do {
            recordsPath = Utility.getLocalFilePath(Utility.recordFileName)
            videoWritter = try AVAssetWriter(url: recordsPath!, fileType: .mov)
            
            videoWritterInput.expectsMediaDataInRealTime = true
            if videoWritter.canAdd(videoWritterInput) {
                videoWritter.add(videoWritterInput)
            }

            videoWritter.startWriting()
        } catch let error {
            debugPrint(error.localizedDescription)
        }
    }
}

extension VideoRecorder: DetectionDelegate {
    func detection(_ detection: Detection, predictions: [VNRecognizedObjectObservation]) {
        print("person detected")
        startRecord()
    }
}
