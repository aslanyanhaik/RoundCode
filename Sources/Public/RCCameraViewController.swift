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

public final class RCCameraViewController: UIViewController, UIImagePickerControllerDelegate {
  
  //MARK: Public properties
  public weak var delegate: RCCameraViewControllerDelegate?
  public var coder = RCCoder()
  override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    .portrait
  }
  public override var prefersStatusBarHidden: Bool {
    true
  }
  //Private properties
  private var captureSession = AVCaptureSession()
  private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
  private var maskLayer = CAShapeLayer()
  private var circleLayer = CAShapeLayer()
  private lazy var cameraView: UIView = {
    let cameraView = UIView()
    cameraView.backgroundColor = .black
    self.view.addSubview(cameraView)
    cameraView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 0).isActive = true
    cameraView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: 0).isActive = true
    cameraView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 0).isActive = true
    cameraView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 0).isActive = true
    return cameraView
  }()
  
  //MARK: Inits
  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    modalPresentationStyle = .fullScreen
    view.backgroundColor = .black
  }
  
  public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    modalPresentationStyle = .fullScreen
    view.backgroundColor = .black
  }
  
  public convenience init() {
    self.init(nibName: nil, bundle: nil)
    modalPresentationStyle = .fullScreen
    view.backgroundColor = .black
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
    cameraView.layer.addSublayer(maskLayer)
    cameraView.layer.addSublayer(circleLayer)
    configureCancelButton()
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
    calculateScanArea()
  }
}

//MARK: Private methods
extension RCCameraViewController {
  
  private func configureCancelButton() {
    let cancelButton = UIButton(type: .custom)
    cancelButton.addTarget(self, action: #selector(cancelPressed), for: .touchUpInside)
    cancelButton.setImage(UIImage(systemName: "xmark"), for: .normal)
    cancelButton.tintColor = .white
    view.addSubview(cancelButton)
    cancelButton.translatesAutoresizingMaskIntoConstraints = false
    view.trailingAnchor.constraint(equalTo: cancelButton.trailingAnchor, constant: 30).isActive = true
    cancelButton.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: 20).isActive = true
  }
  
  @objc private func cancelPressed() {
    captureSession.stopRunning()
    delegate?.cameraViewControllerDidCancel()
    dismiss(animated: true)
  }
  
  private func configureMaskLayer() {
    let path = UIBezierPath(roundedRect: view.bounds, cornerRadius: 0)
    let centerPoint = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
    let radius = min(view.bounds.width, view.bounds.height) * 0.9 / 2
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
  
  private func configureVideoStream() {
    guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
    do {
      captureSession.sessionPreset = .hd1280x720
      calculateScanArea()
      let input = try AVCaptureDeviceInput(device: captureDevice)
      input.device.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: 30)
      captureSession.addInput(input)
      let videoOutput = AVCaptureVideoDataOutput()
      videoOutput.setSampleBufferDelegate(self, queue: .main)
      videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
      captureSession.addOutput(videoOutput)
    } catch {
      print(error.localizedDescription)
    }
  }
  
  private func calculateScanArea() {
//    let actualWidth = view.frame.height / 16 * 9
//    var sideArea: CGFloat = min(view.bounds.width, view.bounds.height) * 0.9 * 0.2
//    sideArea += (actualWidth - min(view.bounds.width, view.bounds.height) * 0.9) / 2
//    let area = sideArea / min(view.bounds.width, view.bounds.height) * 720
//    coder.set(scanArea: Int(area))
  }
  
  private func configureVideoPreview(orientation: AVCaptureVideoOrientation = .portrait) {
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
    connection.videoOrientation = .portrait
    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
    CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
    let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)
    let bufferHeight = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)
    let bufferWidth = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0)
    let size = min(bufferWidth, bufferHeight)
    let origin = (max(bufferWidth, bufferHeight) - size) / 2
    let lumaBaseAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0)?.advanced(by: bytesPerRow * origin)
    let lumaCopy = UnsafeMutableRawPointer.allocate(byteCount: bytesPerRow * size, alignment: MemoryLayout<UInt8>.alignment)
    lumaCopy.copyMemory(from: lumaBaseAddress!, byteCount: bytesPerRow * size)
    coder.imageDecoder.size = size
    coder.imageDecoder.bytesPerRow = bytesPerRow
    if let message = try? coder.decode(buffer: lumaCopy.assumingMemoryBound(to: UInt8.self)) {
      captureSession.stopRunning()
      delegate?.cameraViewController(didFinishPickingScanning: message)
      dismiss(animated: true)
    }
    lumaCopy.deallocate()
    CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
  }
}
