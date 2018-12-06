import UIKit
import AVFoundation
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    var mutableAttributedString = NSMutableAttributedString()
    let label: UILabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initLabel()
        setupCaptureSession()
        
        view.addSubview(label)
        setupLabel()
    }
    
    func initLabel() {
        let defaultText = "HuazhengLiu's project"
        self.label.adjustsFontSizeToFitWidth = true
        self.label.translatesAutoresizingMaskIntoConstraints = false
        self.label.numberOfLines = 0
        let myAttributes = [
            NSAttributedString.Key.strokeColor : UIColor.white,
            NSAttributedString.Key.foregroundColor : UIColor.black,
            NSAttributedString.Key.strokeWidth : -4.0,
            NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 30)
            ] as [NSAttributedString.Key : Any]
        mutableAttributedString = NSMutableAttributedString(string: defaultText, attributes: myAttributes);
        self.label.attributedText = mutableAttributedString
    }
    
    func updateLabel(text: String) {
        mutableAttributedString.mutableString.setString(text)
        self.label.attributedText = mutableAttributedString
    }
    
    func setupLabel() {
        label.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        label.topAnchor.constraint(equalTo: view.topAnchor, constant: 50).isActive = true
    }
    
    func setupCaptureSession() {
        let captureSession = AVCaptureSession()
        let availableDevices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back).devices
        do {
            if let captureDevice = availableDevices.first {
                captureSession.addInput(try AVCaptureDeviceInput(device: captureDevice))
            }
        } catch {
            print(error.localizedDescription)
        }
        let captureOutput = AVCaptureVideoDataOutput()
        captureSession.addOutput(captureOutput)
        
        captureOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.frame
        view.layer.addSublayer(previewLayer)
        
        captureSession.startRunning()
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let model = try? VNCoreMLModel(for: Resnet50().model) else { return }
        let request = VNCoreMLRequest(model: model) { (finishedRequest, error) in
            guard let results = finishedRequest.results as? [VNClassificationObservation] else { return }
            guard let Observation = results.first else { return }
            
            DispatchQueue.main.async(execute: {
                self.updateLabel(text: "\(Observation.identifier)\n confidence: \(Observation.confidence)")
            })
        }
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
    

}
