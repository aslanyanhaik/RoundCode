//  MIT License

//  Copyright (c) 2020 Haik Aslanyan

//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:

//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.

//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import UIKit
import AVFoundation

public class RCCameraViewController: UIViewController, UIImagePickerControllerDelegate {
  
  //MARK: Properties
  public weak var delegate: RCCameraViewControllerDelegate?
  private var captureSession = AVCaptureSession()
  private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
  private var maskLayer = CAShapeLayer()
  private var circleLayer = CAShapeLayer()
  
  //MARK: Inits
  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    modalPresentationStyle = .fullScreen
  }
  
  public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    modalPresentationStyle = .fullScreen
  }
  
  public convenience init() {
    self.init(nibName: nil, bundle: nil)
    modalPresentationStyle = .fullScreen
  }
  
  deinit {
    videoPreviewLayer?.removeFromSuperlayer()
  }
}

//MARK: ViewController lifecycle
extension RCCameraViewController {
  public override func viewDidLoad() {
    super.viewDidLoad()
    configureMaskLayer()
    configureVideoStream()
    configureVideoPreview()
    view.layer.addSublayer(maskLayer)
    view.layer.addSublayer(circleLayer)
  }
  
  public override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    captureSession.startRunning()
  }
  
  public override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    captureSession.stopRunning()
  }
  
  public override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    configureMaskLayer()
    videoPreviewLayer?.frame = view.bounds
  }
}

//MARK: Private methods
extension RCCameraViewController {
  
  func configureMaskLayer() {
    let path = UIBezierPath(roundedRect: view.bounds, cornerRadius: 0)
    let centerPoint = CGPoint(x: view.bounds.midX, y: view.bounds.midY - 30)
    let radius = min(view.bounds.width, view.bounds.height) / 2 - 50
    let circlePath = UIBezierPath(arcCenter: centerPoint, radius: radius, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
    path.append(circlePath)
    path.usesEvenOddFillRule = true
    maskLayer.path = path.cgPath
    maskLayer.fillRule = .evenOdd
    maskLayer.fillColor = UIColor(white: 0, alpha: 0.6).cgColor
    circleLayer.path = circlePath.cgPath
    circleLayer.lineWidth = 2
    circleLayer.strokeColor = UIColor.white.cgColor
    circleLayer.fillColor = UIColor.clear.cgColor
  }
  
  func configureVideoStream() {
    guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
    do {
      let input = try AVCaptureDeviceInput(device: captureDevice)
      captureSession.addInput(input)
      let videoOutput = AVCaptureVideoDataOutput()
      videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: .background))
      videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
      captureSession.addOutput(videoOutput)
    } catch {
      print(error.localizedDescription)
    }
  }
  
  func configureVideoPreview(orientation: AVCaptureVideoOrientation = .portrait) {
    videoPreviewLayer?.removeFromSuperlayer()
    videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    videoPreviewLayer?.videoGravity = .resizeAspectFill
    videoPreviewLayer?.connection?.videoOrientation = orientation
    videoPreviewLayer?.frame = view.layer.bounds
    view.layer.addSublayer(videoPreviewLayer!)
  }
}

//MARK: AVCaptureVideoDataOutputSampleBufferDelegate
extension RCCameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
  
  public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    
  }
  
  
}
