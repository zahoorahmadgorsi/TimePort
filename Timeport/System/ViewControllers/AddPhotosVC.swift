//
//  GetPermissionControllerVC.swift
//  GoogleMapDemo
//
//  Created by ViPrak-Rohit on 06/09/24.
//

import UIKit
import GoogleMaps
import CoreLocation
import ARKit
import CoreMotion
import Photos

class AddPhotosVC: UIViewController {
    
    //MARK: - Variables
    var locationManager: CLLocationManager!
    var motionManager: CMMotionManager!
    var currentLocation: CLLocationCoordinate2D?
    var currentHeading: CLLocationDirection?
    var currentTilt: (pitch: Double, roll: Double, yaw: Double)?
    var capturedPhoto: UIImage?
    var previousTilt: (pitch: Double, roll: Double, yaw: Double)?
    
    let imagePicker = UIImagePickerController()
    
    //MARK: - Override Methods 
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if locationManager == nil {
            locationManager = CLLocationManager()
            locationManager?.delegate = self
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
    }
    
    //MARK: - @IBAction
    @IBAction func AddPhotosBTNTapped(_ sender: Any) {
        if locationManager == nil {
            let alert = UIAlertController(title: "Error", message: "Looks like you didn't gave permission for location.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Okay", style: UIAlertAction.Style.default) {_ in
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
            })
            self.present(alert, animated: true, completion: nil)
        } else {
            present(imagePicker, animated: true, completion: nil)
        }
    }
    
    //MARK: - Methods
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if #available(iOS 14.0, *) {
            switch manager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                manager.startUpdatingLocation()
                setupLocationManager()
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

    func setupLocationManager() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }
}

// MARK: - CLLocationManagerDelegate
extension AddPhotosVC: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location.coordinate
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if newHeading.headingAccuracy < 0 {
            currentHeading = newHeading.magneticHeading
        } else {
            currentHeading = newHeading.trueHeading
        }
    }
}

// MARK: - UIImagePickerControllerDelegate
extension AddPhotosVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            capturedPhoto = image
        }
        if let assetURL = info[.referenceURL] as? URL {
            let result = PHAsset.fetchAssets(withALAssetURLs: [assetURL], options: nil)
            if let asset = result.firstObject {
                if let imageName = asset.value(forKey: "filename") as? String {
                    let imageNameWithoutExtension = (imageName as NSString).deletingPathExtension
                    print("Real image name: \(imageNameWithoutExtension )")
                    picker.dismiss(animated: true, completion: nil)
                    let vc = storyboard?.instantiateViewController(withIdentifier: "CapturePhotoVC") as! CapturePhotoVC
                    vc.capturedPhoto = capturedPhoto
                    vc.selectedImageName = imageNameWithoutExtension
                    vc.modalPresentationStyle = .fullScreen
                    navigationController?.present(vc, animated: true)
                }
            }
        } else {
            print("No URL reference found.")
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
