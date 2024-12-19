//
//  CapturePhotoVC.swift
//  Timeport
//
//  Created by ViPrak-Rohit on 01/10/24.
//

import UIKit
import AVFoundation
import CoreLocation
import CoreMotion
import Toast_Swift
import SPIndicator

class CapturePhotoVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, AVCapturePhotoCaptureDelegate {
    
    //MARK: - Variables
    var captureSession: AVCaptureSession!
    var photoOutput: AVCapturePhotoOutput!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var capturedImageView: UIImageView!
    var locationManager: CLLocationManager!
    var motionManager: CMMotionManager!
    var currentLocation: CLLocationCoordinate2D?
    //zahoor started
//    var currentHeading: CLLocationDirection?
    var currentHeading: Double?
    //zahoor ended
    var currentTilt: (pitch: Double, roll: Double, yaw: Double)?
    var capturedPhoto: UIImage?
    var previousTilt: (pitch: Double, roll: Double, yaw: Double)?
    var selectedImageName: String?
    var selectedImageDesc: String?
    
    //MARK: - @IBOutlet
    @IBOutlet weak var cameraPreviewBGView: UIView!
    @IBOutlet weak var capturedImageView1: UIImageView!
    @IBOutlet weak var donBTN: UIButton!
    
    //zahoor started
    var coordinateAtDone: CLLocationCoordinate2D?
    var headingAtDone: CLLocationDirection?
    var tiltAtDone: (pitch: Double, roll: Double, yaw: Double)?
    //zahooe ended
    
    //MARK: - Override Methods
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startCamera()
        NotificationCenter.default.addObserver(self, selector: #selector(handleDeviceOrientationChange), name: UIDevice.orientationDidChangeNotification, object: nil)
        if let connection = previewLayer.connection, connection.isVideoOrientationSupported {
            connection.videoOrientation = getCurrentVideoOrientation()
        }
        if locationManager == nil {
            locationManager = CLLocationManager()
            locationManager?.delegate = self
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = cameraPreviewBGView.bounds
        if let connection = previewLayer.connection, connection.isVideoOrientationSupported {
            switch UIDevice.current.orientation {
            case .landscapeLeft:
                connection.videoOrientation = .landscapeLeft
            case .landscapeRight:
                connection.videoOrientation = .landscapeRight
            case .portrait:
                connection.videoOrientation = .portrait
            case .portraitUpsideDown:
                connection.videoOrientation = .portraitUpsideDown
            default:
                connection.videoOrientation = .landscapeRight
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCameraPreview()
        NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
        displayCapturedPhoto()
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .landscapeRight
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession.stopRunning()
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }

    //MARK: - @objc
    @objc func handleDeviceOrientationChange() {
        if let connection = previewLayer.connection, connection.isVideoOrientationSupported {
            connection.videoOrientation = getCurrentVideoOrientation()
            previewLayer.frame = cameraPreviewBGView.bounds
        }
    }
    
    @objc func deviceOrientationDidChange() {
        guard let connection = previewLayer.connection else { return }
        if connection.isVideoOrientationSupported {
            switch UIDevice.current.orientation {
            case .landscapeLeft:
                connection.videoOrientation = .landscapeRight
            case .landscapeRight:
                connection.videoOrientation = .landscapeLeft
            case .portrait:
                connection.videoOrientation = .portrait
            case .portraitUpsideDown:
                connection.videoOrientation = .portraitUpsideDown
            default:
                connection.videoOrientation = .landscapeRight
            }
            previewLayer.frame = cameraPreviewBGView.bounds
        }
    }
    
    //MARK: - Setup View Methods
    func setupLocationManager() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }
    
    func setupMotionManager() {
        motionManager = CMMotionManager()
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
            motionManager.startDeviceMotionUpdates(to: OperationQueue.main) { (motion, error) in
                if let motion = motion {
                    let newTilt = (pitch: motion.attitude.pitch * (180 / .pi),
                                   roll: motion.attitude.roll * (180 / .pi),
                                   yaw: motion.attitude.yaw * (180 / .pi))
                    if let previous = self.previousTilt {
                        if abs(previous.pitch - newTilt.pitch) > 1 ||
                            abs(previous.roll - newTilt.roll) > 1 ||
                            abs(previous.yaw - newTilt.yaw) > 1 {
                            self.currentTilt = newTilt
                        }
                    } else {
                        self.currentTilt = newTilt
                    }
                    self.previousTilt = self.currentTilt
                }
            }
        }
    }

    func setupCameraPreview() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        guard let backCamera = AVCaptureDevice.default(for: .video) else {
            print("Unable to access back camera!")
            return
        }
        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            photoOutput = AVCapturePhotoOutput()
            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
            }
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = cameraPreviewBGView.bounds
            cameraPreviewBGView.layer.insertSublayer(previewLayer, at: 0)
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
            }
        } catch let error  {
            print("Error Unable to initialize back camera:  \(error.localizedDescription)")
        }
    }
                
    //MARK: - @IBAction
    @IBAction func doneBTNTapped(_ sender: Any) {
        //zahoor started
        guard let coordinate = currentLocation,
              let heading = currentHeading,
              let tilt = currentTilt else { return }
        self.coordinateAtDone = coordinate
        self.headingAtDone = heading
        self.tiltAtDone = tilt
        //zahoor ended
        
        self.donBTN.isHidden = true
        self.presentAlertWithTextField(on: self)
    }
    
    //MARK: - Other Methods
    func startCamera() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }
    
    func getCurrentVideoOrientation() -> AVCaptureVideoOrientation {
        let deviceOrientation = UIDevice.current.orientation
        switch deviceOrientation {
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .portrait:
            return .portrait
        default:
            return .landscapeRight
        }
    }
    
    func displayCapturedPhoto() {
        guard let image = capturedPhoto else {
            print("No photo to display")
            return
        }
        capturedImageView1.image = image
        capturedImageView1.contentMode = .scaleAspectFit
        capturedImageView1.layer.borderColor = UIColor.yellow.cgColor
        capturedImageView1.layer.borderWidth = 2.0
        capturedImageView1.layer.cornerRadius = 10.0
        capturedImageView1.clipsToBounds = true
        cameraPreviewBGView.addSubview(capturedImageView1)
        capturedImageView1.translatesAutoresizingMaskIntoConstraints = false
        let aspectRatio = image.size.width / image.size.height
        NSLayoutConstraint.activate([
            capturedImageView1.centerXAnchor.constraint(equalTo: cameraPreviewBGView.centerXAnchor),
            capturedImageView1.centerYAnchor.constraint(equalTo: cameraPreviewBGView.centerYAnchor),
            capturedImageView1.widthAnchor.constraint(lessThanOrEqualTo: cameraPreviewBGView.widthAnchor, multiplier: 0.9),
            capturedImageView1.heightAnchor.constraint(lessThanOrEqualTo: cameraPreviewBGView.heightAnchor, multiplier: 0.9),
            capturedImageView1.widthAnchor.constraint(equalTo: capturedImageView1.heightAnchor, multiplier: aspectRatio)
        ])
    }
    
    func presentAlertWithTextField(on viewController: UIViewController) {
        let alertController = UIAlertController(title: "Message", message: "Name this location", preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.placeholder = "Enter text here"
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { action in
            self.donBTN.isHidden = false
        }

        alertController.addAction(cancelAction)
        
        let submitAction = UIAlertAction(title: "Submit", style: .default) { _ in
            if let inputText = alertController.textFields?.first?.text, !inputText.isEmpty {
                self.selectedImageName = inputText
//                DispatchQueue.main.async {
//                    self.dismiss(animated: true)
//                }
                self.presentAlertForGetImageDesc()
            } else {
                SPIndicator.present(title: "Alert", message: "Please enter the name", preset: .error, from: .top)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.presentAlertWithTextField(on: self)
                }
            }
        }
        alertController.addAction(submitAction)
        viewController.present(alertController, animated: true, completion: nil)
    }
    
    func presentAlertForGetImageDesc() {
        let alert = UIAlertController(title: "Describe the image location",
                                      message: "",
                                      preferredStyle: .alert)
        let textView = UITextView()
        //        textView.borderColor = .black
        //        textView.borderWidth = 1.0
        textView.delegate = self
        textView.text = "Enter Description here.."
        textView.textColor = .lightGray
        alert.view.addSubview(textView)
        
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.topAnchor.constraint(equalTo: alert.view.topAnchor, constant: 50).isActive = true
        textView.rightAnchor.constraint(equalTo: alert.view.rightAnchor, constant: -20).isActive = true
        textView.leftAnchor.constraint(equalTo: alert.view.leftAnchor, constant: 20).isActive = true
        textView.bottomAnchor.constraint(equalTo: alert.view.bottomAnchor, constant: -60).isActive = true
        textView.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
        alert.view.translatesAutoresizingMaskIntoConstraints = false
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { action in
            self.donBTN.isHidden = false
        }

        alert.addAction(cancelAction)

        alert.addAction(UIAlertAction(title: "Submit", style: .default, handler: { (_) in
            if let inputText = textView.text, !inputText.isEmpty, inputText != "Enter Description here.." {
                SPIndicator.present(title: inputText, message: "Photo saved successfully!", preset: .done, from: .top)
                self.selectedImageDesc = inputText
                self.saveCapturedData()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.dismiss(animated: true)
                }
            } else {
                SPIndicator.present(title: "Alert", message: "Please enter the descriptions", preset: .error, from: .top)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.presentAlertForGetImageDesc()
                }
            }
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Save Captured Data
    func saveCapturedData() {
        //zahoor started
//        guard let coordinate = currentLocation,
//              let heading = currentHeading,
//              let tilt = currentTilt else { return }
        guard let coordinate = self.coordinateAtDone,
              let heading = self.headingAtDone,
              let tilt = self.tiltAtDone else { return }

        savePhotoData(coordinate: coordinate, heading: heading, tilt: tilt)

        //zahoor ended
    }
    
    func savePhotoData(coordinate: CLLocationCoordinate2D
                       , heading: CLLocationDirection
                       , tilt: (pitch: Double
                                , roll: Double
                                , yaw: Double)
                        ) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        //zahoor started
        //let normalizedHeading = (heading >= 0 && heading <= 360) ? heading : fmod(heading + 360, 360)
        let normalizedHeading = heading
        //zahoor ended
        guard let capturedPhoto = self.capturedPhoto else { return }
        context.perform {
            let photoEntity = PhotoEntity(context: context)
            photoEntity.photoData = capturedPhoto.pngData()
            photoEntity.locationLatitude = coordinate.latitude
            photoEntity.locationLongitude = coordinate.longitude
            photoEntity.heading = normalizedHeading
            photoEntity.tiltPitch = tilt.pitch
            photoEntity.tiltRoll = tilt.roll
            photoEntity.tiltYaw = tilt.yaw
            photoEntity.imageName = self.selectedImageName
            photoEntity.imageDesc = self.selectedImageDesc
            do {
                try context.save()
                print("Photo data saved successfully!")
                //                    self.dismiss(animated: true)
            } catch {
                print("Failed to save photo data: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension CapturePhotoVC: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location.coordinate
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
//        print("magneticHeading: \(newHeading.magneticHeading), trueHeading: \(newHeading.trueHeading), headingAccuracy: \(newHeading.headingAccuracy)")
        if newHeading.headingAccuracy < 0 {
            self.currentHeading = newHeading.magneticHeading
        } else {
            self.currentHeading = newHeading.trueHeading
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if #available(iOS 14.0, *) {
            switch manager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                manager.startUpdatingLocation()
                manager.startUpdatingHeading()
                setupLocationManager()
                setupMotionManager()
            case .restricted, .denied:
                let alert = UIAlertController(title: "Error", message: "Looks like you didn't gave permission for location.", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Okay", style: UIAlertAction.Style.default) {_ in
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
                })
                self.present(alert, animated: true, completion: nil)
                break
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            default:
                break
            }
        } else {
        }
    }
}

//MARK: - UITextViewDelegate
extension CapturePhotoVC: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
        let numberOfChars = newText.count
        return numberOfChars < 201 //Max 100 chars
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = ""
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text == "" {
            textView.text = "Enter Description here.."
            textView.textColor = UIColor.lightGray
        }
    }
}


