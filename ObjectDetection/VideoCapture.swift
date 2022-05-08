import AVFoundation
import CoreVideo
import UIKit
import Photos

public protocol VideoCaptureDelegate: class {
    func videoCapture(_ capture: VideoCapture, didCaptureVideoFrame: CMSampleBuffer)
}

public class VideoCapture: NSObject {
    public var previewLayer: AVCaptureVideoPreviewLayer?
    public weak var delegate: VideoCaptureDelegate?
    
    let captureSession = AVCaptureSession()
    let videoOutput = AVCaptureVideoDataOutput()
    let queue = DispatchQueue(label: "net.machinethink.camera-queue")
    
    // You can't use AVCaptureVideoDataOutput and AVCaptureMovieFileOutput on the same time.
    // ref: https://stackoverflow.com/a/63008365
    var videoWritter: AVAssetWriter!
    lazy var videoWritterInput = AVAssetWriterInput(mediaType: .video, outputSettings: [
        AVVideoCodecKey : AVVideoCodecType.h264,
        AVVideoWidthKey : 720,
        AVVideoHeightKey : 1280,
        AVVideoCompressionPropertiesKey : [
            // FIXME: what's the suitable value?
            AVVideoAverageBitRateKey : 2300000,
        ],
    ])
    
    let duration: CGFloat = 10 // 10s
    var recordsPath: URL?
    var isRecording = false
    var sessionAtSourceTime: CMTime?
    var isWritable: Bool {
        return isRecording && videoWritter != nil && videoWritter.status == .writing
    }
    
    var lastTimestamp = CMTime()
    
    public func setUp(sessionPreset: AVCaptureSession.Preset = .medium,
                      completion: @escaping (Bool) -> Void) {
        queue.async {
            let success = self.setUpCamera(sessionPreset: sessionPreset)
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
    
    func setUpCamera(sessionPreset: AVCaptureSession.Preset) -> Bool {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = sessionPreset
        
        guard let captureDevice = AVCaptureDevice.default(for: AVMediaType.video) else {
            print("Error: no video devices available")
            return false
        }
        
        guard let videoInput = try? AVCaptureDeviceInput(device: captureDevice) else {
            print("Error: could not create AVCaptureDeviceInput")
            return false
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
        previewLayer.connection?.videoOrientation = .portrait
        self.previewLayer = previewLayer
        
        let settings: [String : Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA)
        ]
        
        videoOutput.videoSettings = settings
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: queue)
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        
        // We want the buffers to be in portrait orientation otherwise they are
        // rotated by 90 degrees. Need to set this _after_ addOutput()!
        videoOutput.connection(with: AVMediaType.video)?.videoOrientation = .portrait
        
        captureSession.commitConfiguration()
        return true
    }
    
    public func start() {
        if !captureSession.isRunning {
            captureSession.startRunning()
        }
    }
    
    public func stop() {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }
    
    public func record() {
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
    
    public func stopRecord() {
        guard isRecording else { return }
        isRecording = false
        videoWritterInput.markAsFinished()
        videoWritter.finishWriting { [weak self] in
            self?.sessionAtSourceTime = nil
            if let url = self?.recordsPath {
                let photo = PhotoLibraryHelper()
                photo.save(url)
            }
        }
        print("finished writing")
    }
    
    func setUpWritter() {
        do {
            recordsPath = Utility.getLocalFilePath(Utility.recordFileName)
            videoWritter = try AVAssetWriter(url: recordsPath!, fileType: .mov)
            
//            videoWritterInput.expectsMediaDataInRealTime = true
            if videoWritter.canAdd(videoWritterInput) {
                videoWritter.add(videoWritterInput)
            }

            videoWritter.startWriting()
        } catch let error {
            debugPrint(error.localizedDescription)
        }
    }
    
}

extension VideoCapture: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
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
        
        print("buffer")
        delegate?.videoCapture(self, didCaptureVideoFrame: sampleBuffer)
    }
    
    public func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        //    print("dropped frame")
    }
}
