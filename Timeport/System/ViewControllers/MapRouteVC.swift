//
//  ViewController.swift
//  GoogleMapDemo
//
//  Created by ViPrak-Rohit on 24/08/24.
//

import UIKit
import GoogleMaps
import CoreLocation
import ARKit
import CoreData
import RealityKit
import CoreMotion

class MapRouteVC: UIViewController {
    
    //MARK: - @IBOutlet
    @IBOutlet weak var mapBGView: UIView!
    @IBOutlet weak var selectedLocationIMG: UIImageView!
    @IBOutlet weak var locationDetailBGView: UIView!
    @IBOutlet weak var locationNameLBL: UILabel!
    @IBOutlet weak var locationRoadNameLBL: UILabel!
    
    //MARK: - Variables
    var mapView: GMSMapView!
//    var locationManager: CLLocationManager!
    var locationManager = CLLocationManager()
    var motionManager = CMMotionManager()
    var destinationMarker: GMSMarker!
    var currentMarker: GMSMarker!
    var arView: ARView!
    var borderEntity: Entity?
    var photoEntity: ModelEntity?
    var arrPhotosData: [PhotoEntity]?
    var polyline: GMSPolyline?
    
    var markersArray: [GMSMarker] = []
    
    var selectedLocationLattitde: Double?
    var selectedLocationLongitude: Double?
    var selectedOldPhoto: UIImage?
    var selectedHeading: Double?
    var selectedTiltPitch: Double?
    var selectedImageName: String?
    var selectedImageDesc: String?
    var selectedTiltRoll: Double?
    var selectedTiltYaw: Double?
    var currentHeading: CLLocationDirection = 0.0
    
    var lastBorderColor: UIColor? = nil
    var lastVisibilityState: Bool? = nil
    var visibilityStateBuffer: [Bool] = []
    let bufferSize = 10
    let requiredConsistentFrames = 7
    
    var lastStateChangeTime: TimeInterval = 0
    let minimumDisplayDuration: TimeInterval = 0.5
    
    var storedTexture: TextureResource?
    
    var shouldShowFrame = false
    var anchorEntity = AnchorEntity(world: [0,0,-0.8])
    
    //MARK: -  Override Mehods
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        arrPhotosData = fetchSavedPhotoData()
        if arrPhotosData?.isEmpty == true {
            let alert = UIAlertController(title: "Attention", message: "You don't have any record yet! please create.", preferredStyle: .alert)
            let okayBtn = UIAlertAction(title: "Okay", style: .default) { action in
                self.tabBarController?.selectedIndex = 2
            }
            alert.addAction(okayBtn)
            present(alert, animated: true)
        }
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            self.setupLocationManager()
            self.setupMultipleMarkers()
            if let mapview = self.mapView {
                self.mapView.delegate = self
            }
            if self.currentMarker == nil, let lastLocation = self.locationManager.location?.coordinate {
                if self.mapView != nil {
                    self.mapView.isMyLocationEnabled = true
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let mapView = mapView {
            mapView.removeFromSuperview()
        }
        if selectedOldPhoto != nil || arView != nil{
            if let arrVIew = arView {
                arView.removeFromSuperview()
                photoEntity = nil
                borderEntity = nil
                storedTexture = nil
            }
        }
        selectedLocationLattitde = 0
        selectedLocationLongitude = 0
        locationManager.stopUpdatingLocation()
        currentMarker = nil
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if let mapBGView = mapBGView {
            mapBGView.layoutIfNeeded()
            if let mapView = mapView {
                mapView.frame = mapBGView.bounds
            }
        }
    }
    
    //MARK: - @IBAction
    @IBAction func locationDetailsViewCancelBTNTapped(_ sender: Any) {
        locationDetailBGView.isHidden = true
    }
    
    @IBAction func startRouteBTNTapped(_ sender: Any) {
        guard let userLocation = locationManager.location?.coordinate else {
            print("User location not available")
            return
        }
        locationDetailBGView.isHidden = true
        selectedLocationLattitde = destinationMarker?.position.latitude
        selectedLocationLongitude = destinationMarker?.position.longitude
        drawRoute(from: userLocation, to: destinationMarker!.position)
    }
    
    @IBAction func deletePhotoBTNTapped(_ sender: Any) {
        guard let selectedPhoto = selectedOldPhoto,
              let selectedPhotoData = selectedPhoto.pngData(),
              let photoData = arrPhotosData?.first(where: { $0.photoData == selectedPhotoData }) else {
            print("No photo selected for deletion.")
            return
        }
        let alert = UIAlertController(title: "Alert", message: "Are you sure you want to delete this photo?", preferredStyle: .alert)
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { action in
            self.deletePhotoData(photoData)
            self.removeSelectedMarker(photoData)
            self.locationDetailBGView.isHidden = true
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
}

//MARK: - Init Views Methods
extension MapRouteVC {
    func setupMapView() {
        guard let firstPhotoData = arrPhotosData?.first else { return }
        let camera = GMSCameraPosition.camera(withLatitude: locationManager.location?.coordinate.latitude ?? 0, longitude: locationManager.location?.coordinate.longitude ?? 0, zoom: 15.0)
        mapView = GMSMapView.map(withFrame: .zero, camera: camera)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapBGView.addSubview(mapView)
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: mapBGView.topAnchor),
            mapView.bottomAnchor.constraint(equalTo: mapBGView.bottomAnchor),
            mapView.leadingAnchor.constraint(equalTo: mapBGView.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: mapBGView.trailingAnchor)
        ])
        let destinationCoordinate = CLLocationCoordinate2D(latitude: firstPhotoData.locationLatitude, longitude: firstPhotoData.locationLongitude)
        destinationMarker = GMSMarker(position: destinationCoordinate)
        destinationMarker.title = "Timberlake Pharmacy"
        destinationMarker.snippet = "110 E Main St, Charlottesville, VA 22902"
        destinationMarker.map = mapView
    }
    
    func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.headingFilter = 1
        locationManager.requestWhenInUseAuthorization()
        
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        
//        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
//        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (motion, error) in
//            guard let self = self, let motion = motion else { return }
//            self.updateARObject(using: motion.attitude)
//        }
        self.setupMapView()
    }
    
    func setupMultipleMarkers() {
        if let mapView = mapView {
            mapView.clear()
        }
        guard let photoDataArray = arrPhotosData else { return }
        markersArray.removeAll()
        for photoData in photoDataArray {
            let latitude = photoData.locationLatitude
            let longitude = photoData.locationLongitude
            let photoCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            let marker = GMSMarker(position: photoCoordinate)
            marker.snippet = "Click to view details"
            marker.icon = GMSMarker.markerImage(with: .black)
            marker.userData = photoData
            marker.map = mapView
            markersArray.append(marker)
        }
    }
}


//MARK: - Handle Photos
extension MapRouteVC {
    func fetchSavedPhotoData() -> [PhotoEntity]? {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return nil }
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<PhotoEntity> = PhotoEntity.fetchRequest()
        do {
            let photoEntities = try context.fetch(fetchRequest)
            return photoEntities
        } catch {
            print("Failed to fetch photo data: \(error.localizedDescription)")
            return nil
        }
    }
    
    func deletePhotoData(_ photoEntity: PhotoEntity) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        context.delete(photoEntity)
        do {
            try context.save()
            if let index = arrPhotosData?.firstIndex(of: photoEntity) {
                arrPhotosData?.remove(at: index)
            }
            print("Photo deleted successfully from the database.")
        } catch {
            print("Failed to delete photo: \(error.localizedDescription)")
        }
    }
    
    func removeSelectedMarker(_ photoEntity: PhotoEntity) {
        guard let mapView = mapView else { return }
        for (index, marker) in markersArray.enumerated() where (marker.userData as? PhotoEntity) == photoEntity {
            marker.map = nil
            markersArray.remove(at: index)
            print("Marker removed from the map.")
            break
        }
    }
}


//MARK: - CLLocationManagerDelegate
extension MapRouteVC: CLLocationManagerDelegate, GMSMapViewDelegate {
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        guard let userLocation = locationManager.location?.coordinate else {
            print("User location not available")
            return false
        }
        destinationMarker = marker
        if let photoData = marker.userData as? PhotoEntity {
            print("Got the image: \(photoData)")
            selectedLocationIMG.image = UIImage(data: photoData.photoData!)
            selectedOldPhoto = UIImage(data: photoData.photoData!)
            selectedHeading = photoData.heading
            selectedTiltPitch = photoData.tiltPitch
            selectedTiltRoll = photoData.tiltRoll
            selectedTiltYaw = photoData.tiltYaw
            selectedImageName = photoData.imageName
            selectedImageDesc = photoData.imageDesc
            let url = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(photoData.locationLatitude),\(photoData.locationLongitude)&radius=100&key=AIzaSyDu__0AxD6-yUvUlT9ytQjyw0K4g5d8h70"
            fetchPlaceDetails(url: url)
        }else{
            print("couldn't get the image")
        }
        return true
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let currentCoordinate = location.coordinate
        if currentMarker == nil {
            if mapView != nil {
                self.mapView.isMyLocationEnabled = true
            }
        } else {
            currentMarker.position = currentCoordinate
        }
        print("current location: \(location)")
        let distance = location.distance(from: CLLocation(latitude: selectedLocationLattitde ?? 0, longitude: selectedLocationLongitude ?? 0))
        if distance <= 10 {
            print("Entering viewfinder mode, distance:\(distance)")
            enterViewfinderMode()
        } else {
            exitViewfinderMode()
            print("Exiting viewfinder mode, showing map view. distance:\(distance)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
//        print("newHeading: \(newHeading.trueHeading), selectedHeading:\(selectedHeading ?? 0)")
        let headingDifference = abs(newHeading.trueHeading - (selectedHeading ?? 0))
        
        if newHeading.headingAccuracy < 0 {
            currentHeading = newHeading.magneticHeading
        } else {
            currentHeading = newHeading.trueHeading
        }
        
//        currentHeading = newHeading.trueHeading // True North
        shouldShowFrame = headingDifference < 15 || headingDifference > 345
        if (shouldShowFrame){
            print("Phone is pointing to the desired direction/heading!","shouldShowFrame:\(shouldShowFrame)")
        }
        updateBorderColorBasedOnVisibility()
    }
}

//MARK: - Other Methods
extension MapRouteVC {
    
    func setupARView() {
        arView = ARView(frame: .zero)
        arView.translatesAutoresizingMaskIntoConstraints = false
        arView.automaticallyConfigureSession = false
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        arView.session.run(config)
        arView.session.delegate = self
        mapBGView.addSubview(arView)
        NSLayoutConstraint.activate([
            arView.topAnchor.constraint(equalTo: view.topAnchor),
            arView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            arView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            arView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        arView.addGestureRecognizer(tapGestureRecognizer)
        
        setupBorderEntity()
        showOldPhoto()
    }
        
    func setupBorderEntity() {
        guard let image = selectedOldPhoto else {
            print("No old photo to set borders")
            return
        }
        let aspectRatio = image.size.width / image.size.height
        let borderWidth: Float = 0.7
        let borderHeight: Float = borderWidth / Float(aspectRatio)
        let borderThickness: Float = 0.02
        let borderMaterial = UnlitMaterial(color: .red)
        let topBorderFront = ModelEntity(mesh: MeshResource.generatePlane(width: borderWidth, height: borderThickness)
                                         , materials: [borderMaterial])
        topBorderFront.name = "topBorderFront"
        
        let bottomBorderFront = ModelEntity(mesh: MeshResource.generatePlane(width: borderWidth, height: borderThickness)
                                            , materials: [borderMaterial])
        bottomBorderFront.name = "bottomBorderFront"
        
        let leftBorderFront = ModelEntity(mesh: MeshResource.generatePlane(width: borderThickness, height: borderHeight)
                                          , materials: [borderMaterial])
        leftBorderFront.name = "leftBorderFront"
        
        let rightBorderFront = ModelEntity(mesh: MeshResource.generatePlane(width: borderThickness, height: borderHeight)
                                           , materials: [borderMaterial])
        rightBorderFront.name = "rightBorderFront"
        
        let topBorderBack = topBorderFront.clone(recursive: true)
        topBorderBack.transform = Transform(pitch: .pi, yaw: 0, roll: 0)
        
        let bottomBorderBack = bottomBorderFront.clone(recursive: true)
        bottomBorderBack.transform = Transform(pitch: .pi, yaw: 0, roll: 0)
        
        let leftBorderBack = leftBorderFront.clone(recursive: true)
        leftBorderBack.transform = Transform(pitch: .pi, yaw: 0, roll: 0)
        
        let rightBorderBack = rightBorderFront.clone(recursive: true)
        rightBorderBack.transform = Transform(pitch: .pi, yaw: 0, roll: 0)
        
        topBorderFront.position = SIMD3<Float>(0, borderHeight / 2, -0.001)
        bottomBorderFront.position = SIMD3<Float>(0, -borderHeight / 2, -0.001)
        leftBorderFront.position = SIMD3<Float>(-borderWidth / 2, 0, -0.001)
        rightBorderFront.position = SIMD3<Float>(borderWidth / 2, 0, -0.001)
        
        topBorderBack.position = topBorderFront.position
        bottomBorderBack.position = bottomBorderFront.position
        leftBorderBack.position = leftBorderFront.position
        rightBorderBack.position = rightBorderFront.position
        
        borderEntity = Entity()
        borderEntity?.addChild(topBorderFront)
        borderEntity?.addChild(bottomBorderFront)
        borderEntity?.addChild(leftBorderFront)
        borderEntity?.addChild(rightBorderFront)
        borderEntity?.addChild(topBorderBack)
        borderEntity?.addChild(bottomBorderBack)
        borderEntity?.addChild(leftBorderBack)
        borderEntity?.addChild(rightBorderBack)
        
        let borderPosition = SIMD3<Float>(0, 0, -0.8)
        //let anchorEntity = AnchorEntity(world: borderPosition)
        anchorEntity = AnchorEntity(world: borderPosition)
        anchorEntity.addChild(borderEntity!)
        arView.scene.addAnchor(anchorEntity)

        
//        print("Borders set with dimensions: \(borderWidth) x \(borderHeight)")
        //zahoor started
        //Moving to the direction of the photo
//        let newPosition = createSIMD3Position(heading: self.selectedHeading ?? 90.0 // Facing East
//                                              , pitch: self.selectedTiltPitch ?? 10.0  // 10 degrees upward tilt
//                                              , roll: self.selectedTiltRoll ??  0.0    // No left/right tilt
////                                              , yaw: self.selectedTiltYaw ?? 90.0    // Aligns with heading
//                                            )
//        let newPosition = SIMD3<Float>(0.5, 0, -0.8)
//        print("newPosition: \(newPosition)")
//        var transform = anchorEntity.transform
//        transform.translation = newPosition
//        // Animate over 2 seconds
//        anchorEntity.move(to: transform, relativeTo: nil, duration: 2.0, timingFunction: .easeInOut)
    }

    func createSIMD3Position(heading: CLLocationDirection, pitch: Double, roll: Double) -> SIMD3<Float> {
        // Convert degrees to radians
        let yawRadians = Float(heading) * .pi / 180.0   // Heading (Yaw)
        let pitchRadians = Float(pitch) * .pi / 180.0  // Tilt Up/Down
        let rollRadians = Float(roll) * .pi / 180.0    // Tilt Left/Right

        // Distance to position the point (change as needed)
        let distance: Float = 1.0
        
        // Calculate the 3D position using spherical coordinates
        let x = distance * cos(pitchRadians) * sin(yawRadians)
        let y = distance * sin(pitchRadians)
        let z = -distance * cos(pitchRadians) * cos(yawRadians) // Negative Z is forward
        
        print("SIMD3 Position: x: \(x), y: \(y), z: \(z)")
        return SIMD3<Float>(x, y, z)
    }
    
    //zahoor ended
    
    func showOldPhoto() {
        guard let image = selectedLocationIMG.image else {
            print("No old photo to display")
            return
        }
        let correctedImage = image.fixedOrientation()
        let aspectRatio = correctedImage.size.width / correctedImage.size.height
        let photoPlaneWidth: Float = 0.7
        let photoPlaneHeight: Float = photoPlaneWidth / Float(aspectRatio)
        do {
            storedTexture = try TextureResource.generate(from: correctedImage.cgImage!, options: .init(semantic: .none))
        } catch {
            print("Error generating texture: \(error)")
            return
        }
        var photoMaterial = SimpleMaterial(color: .white, roughness: 0.5, isMetallic: false)
        photoMaterial.baseColor = .texture(storedTexture!)
        photoEntity = ModelEntity(mesh: MeshResource.generatePlane(width: photoPlaneWidth, height: photoPlaneHeight), materials: [photoMaterial])
        photoEntity?.transform.rotation = simd_quatf(angle: 0, axis: SIMD3<Float>(0, 0, 1))
        photoEntity?.position = SIMD3<Float>(0, 0, 0)
        borderEntity?.addChild(photoEntity!)
        print("Photo entity added with size: \(photoPlaneWidth) x \(photoPlaneHeight)")
    }
    
    func enterViewfinderMode() {
        if selectedOldPhoto == nil || arView == nil{
            return
        } else {
            mapView.isHidden = true
            arView.isHidden = false
            let configuration = ARWorldTrackingConfiguration()
            arView.session.run(configuration)
            UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
            UIViewController.attemptRotationToDeviceOrientation()
            borderEntity?.isEnabled = true
        }
    }
    
    func exitViewfinderMode() {
        if selectedOldPhoto == nil || arView == nil {
            return
        } else {
            arView.isHidden = true
            if let mapview = mapView {
                mapView.isHidden = false
            }
            arView.session.pause()
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
            UIViewController.attemptRotationToDeviceOrientation()
            borderEntity?.isEnabled = false
        }
    }
    
    func updateBorderColorBasedOnVisibility() {
        guard let borderEntity = borderEntity else {
            setBorderColorWithFade(.red)
            return
        }
        let cameraTransform = arView.cameraTransform
        let borderPosition = borderEntity.position(relativeTo: nil)
        let cameraToBorderVector = normalize(borderPosition - cameraTransform.translation)
        let isFacingCorrectDirection: Bool = {
            guard let photoEntity = photoEntity else { return false }
            let photoNormal = normalize(SIMD3(photoEntity.transform.matrix.columns.2.x,
                                              photoEntity.transform.matrix.columns.2.y,
                                              photoEntity.transform.matrix.columns.2.z))
            return dot(cameraToBorderVector, photoNormal) < -0.2
        }()
        let isOnScreen: Bool = {
            guard let screenPoint = arView.project(borderPosition) else { return false }
            let margin: CGFloat = 50.0
            let extendedBounds = arView.bounds.insetBy(dx: -margin, dy: -margin)
            return extendedBounds.contains(screenPoint)
        }()
        print("isFacingCorrectHeading:\(isFacingCorrectDirection)", "isOnScreen:\(isOnScreen)")
        if isFacingCorrectDirection {
            setBorderColorWithFade(isOnScreen ? .green : .red)
        } else {
            setBorderColorWithFade(.red)
        }
        updatePhotoVisibility(isVisible: isOnScreen && isFacingCorrectDirection)
    }
    
    func setBorderColorWithFade(_ color: UIColor) {
        guard let borderEntity = borderEntity else { return }
        let newMaterial = UnlitMaterial(color: color)
        for child in borderEntity.children {
            if let modelEntity = child as? ModelEntity, child.name.contains("Border") {
                modelEntity.model?.materials = [newMaterial]
            }
        }
    }
    
    func removeOldPhoto() {
        photoEntity?.removeFromParent()
        photoEntity = nil
        print("Old photo is removed.")
    }
    
    func updatePhotoVisibility(isVisible: Bool) {
        guard let modelEntity = photoEntity else { return }
        if var material = modelEntity.model?.materials.first as? SimpleMaterial {
            if isVisible {
                if let texture = storedTexture {
                    material.baseColor = MaterialColorParameter.texture(texture)
                }
            } else {
                material.baseColor = MaterialColorParameter.color(.clear)
            }
            modelEntity.model?.materials = [material]
        }
    }
    

    
    func testPhotoDisplay() {
        guard let image = selectedLocationIMG.image else { return }
        let correctedImage = image.fixedOrientation()
        let aspectRatio = correctedImage.size.width / correctedImage.size.height
        let photoPlaneWidth: Float = 0.7
        let photoPlaneHeight: Float = photoPlaneWidth / Float(aspectRatio)
        do {
            storedTexture = try TextureResource.generate(from: correctedImage.cgImage!, options: .init(semantic: .none))
        } catch {
            print("Error generating texture: \(error)")
            return
        }
        var photoMaterial = SimpleMaterial(color: .white, roughness: 0.5, isMetallic: false)
        photoMaterial.baseColor = .texture(storedTexture!)
        
        let testPhotoEntity = ModelEntity(mesh: MeshResource.generatePlane(width: photoPlaneWidth, height: photoPlaneHeight), materials: [photoMaterial])
        testPhotoEntity.position = SIMD3<Float>(0, 0, -1)
        let anchor = AnchorEntity(world: SIMD3<Float>(0, 0, -1))
        anchor.addChild(testPhotoEntity)
        arView.scene.addAnchor(anchor)
        print("Test photo entity added with size: \(photoPlaneWidth) x \(photoPlaneHeight)")
    }
}

//MARK: - ARSessionDelegate
extension MapRouteVC: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        arView.addGestureRecognizer(tapGestureRecognizer)
        updateBorderColorBasedOnVisibility()
    }
}

//MARK: - AR Touch Handle
extension MapRouteVC {
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        let touchLocation = sender.location(in: arView)
        handleTouchEvent(touchLocation)
    }
    
    func handleTouchEvent(_ touchLocation: CGPoint) {
        guard let borderEntity = borderEntity, let photoEntity = photoEntity else { return }
        let borderPosition = borderEntity.position(relativeTo: nil)
        let cameraTransform = arView.cameraTransform
        let cameraToBorderVector = normalize(borderPosition - cameraTransform.translation)
        let photoNormal = normalize(SIMD3<Float>(photoEntity.transform.matrix.columns.2.x,
                                                 photoEntity.transform.matrix.columns.2.y,
                                                 photoEntity.transform.matrix.columns.2.z))
        let isInFront = dot(cameraToBorderVector, photoNormal) < 0
        let isOnScreen: Bool
        if let screenPoint = arView.project(borderPosition) {
            let margin: CGFloat = 50.0
            let extendedBounds = arView.bounds.insetBy(dx: -margin, dy: -margin)
            isOnScreen = extendedBounds.contains(screenPoint)
        } else {
            isOnScreen = false
        }
        if isOnScreen && isInFront {
            if isTouchInsideBorderRegion(touchLocation) {
                print("Touch inside green border")
                triggerContentTapEvent()
            }
        }
    }
    
    func triggerContentTapEvent() {
        print("Green border content tapped!")
    }
    
    func isTouchInsideBorderRegion(_ touchLocation: CGPoint) -> Bool {
        let results = arView.raycast(from: touchLocation, allowing: .existingPlaneGeometry, alignment: .any)
        if results.isEmpty {
            print("No raycast results.")
            let vc = storyboard?.instantiateViewController(withIdentifier: "ShowPhotoVC") as! ShowPhotoVC
            vc.selectedImage = selectedOldPhoto
            vc.imageName = selectedImageName ?? ""
            vc.discription = selectedImageDesc ?? ""
            vc.modalPresentationStyle = .fullScreen
            navigationController?.present(vc, animated: true)
            return false
        }
        guard let result = results.first else { return false }
        print("Raycast hit at: \(result.worldTransform.columns.3)")
        let intersectionPoint = SIMD3<Float>(result.worldTransform.columns.3.x,
                                             result.worldTransform.columns.3.y,
                                             result.worldTransform.columns.3.z)
        return isPointInsidePhotoBounds(intersectionPoint)
    }
    
    func isPointInsidePhotoBounds(_ point: SIMD3<Float>) -> Bool {
        guard let photoEntity = photoEntity else { return false }
        let photoBounds = getPhotoEntityBoundingBox(photoEntity)
        return pointIsInsideBoundingBox(point, boundingBox: photoBounds)
    }
    
    func getPhotoEntityBoundingBox(_ photoEntity: Entity) -> (min: SIMD3<Float>, max: SIMD3<Float>) {
        let min = photoEntity.position(relativeTo: nil) - photoEntity.scale / 2.0
        let max = photoEntity.position(relativeTo: nil) + photoEntity.scale / 2.0
        return (min, max)
    }
    
    func pointIsInsideBoundingBox(_ point: SIMD3<Float>, boundingBox: (min: SIMD3<Float>, max: SIMD3<Float>)) -> Bool {
        return point.x >= boundingBox.min.x && point.x <= boundingBox.max.x &&
        point.y >= boundingBox.min.y && point.y <= boundingBox.max.y &&
        point.z >= boundingBox.min.z && point.z <= boundingBox.max.z
    }
}

//MARK: - Place Details
extension MapRouteVC {
    func fetchPlaceDetails(url: String) {
        guard let url = URL(string: url) else { return }
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                print("Failed to fetch place details: \(error)")
                return
            }
            guard let data = data else {
                print("No data found")
                return
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let results = json["results"] as? [[String: Any]],
                   !results.isEmpty {
                    if let firstPlace = results.first,
                       let placeId = firstPlace["place_id"] as? String {
                        self.fetchDetailedPlaceInfo(placeId: placeId)
                    }
                } else {
                    print("No place results found")
                }
                
            } catch let jsonError {
                print("Failed to decode JSON: \(jsonError)")
            }
        }.resume()
    }
    
    func fetchDetailedPlaceInfo(placeId: String) {
        let detailsURL = "https://maps.googleapis.com/maps/api/place/details/json?place_id=\(placeId)&key=AIzaSyDu__0AxD6-yUvUlT9ytQjyw0K4g5d8h70"
        guard let url = URL(string: detailsURL) else { return }
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                print("Failed to fetch detailed place info: \(error)")
                return
            }
            guard let data = data else {
                print("No data found")
                return
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let result = json["result"] as? [String: Any] {
                    if let formattedAddress = result["formatted_address"] as? String,
                       let name = result["name"] as? String {
                        print("Place Name: \(name), Detailed Address: \(formattedAddress)")
                        DispatchQueue.main.async {
                            self.locationDetailBGView.isHidden = false
                            self.locationNameLBL.text = self.selectedImageName
                            self.locationRoadNameLBL.text = formattedAddress
                        }
                    }
                } else {
                    print("No detailed place info found")
                }
            } catch let jsonError {
                print("Failed to decode JSON: \(jsonError)")
            }
        }.resume()
    }
    
    func drawRoute(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) {
        let originString = "\(origin.latitude),\(origin.longitude)"
        let destinationString = "\(destination.latitude),\(destination.longitude)"
        let urlString = "https://maps.googleapis.com/maps/api/directions/json?origin=\(originString)&destination=\(destinationString)&key=AIzaSyDu__0AxD6-yUvUlT9ytQjyw0K4g5d8h70"
        guard let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                print("Error fetching directions: \(error)")
                return
            }
            guard let data = data else { return }
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    print("Directions JSON: \(json)")
                    guard let routes = json["routes"] as? [Any], let route = routes.first as? [String: Any] else {
                        print("No routes found.")
                        return
                    }
                    guard let overviewPolyline = route["overview_polyline"] as? [String: Any],
                          let polylineString = overviewPolyline["points"] as? String else {
                        print("No polyline found.")
                        return
                    }
                    DispatchQueue.main.async {
                        self.polyline?.map = nil
                        if let path = GMSPath(fromEncodedPath: polylineString) {
                            let polyline = GMSPolyline(path: path)
                            polyline.strokeWidth = 10.0
                            polyline.geodesic = true
                            let dotColor = GMSStrokeStyle.solidColor(UIColor(hex: "00A4D2"))
                            let gap = GMSStrokeStyle.solidColor(.clear)
                            let spanLengths: [NSNumber] = [10, 10]
                            polyline.spans = GMSStyleSpans(path, [dotColor, gap], spanLengths, .rhumb)
                            polyline.map = self.mapView
                            print("Route drawn successfully.")
                            self.setupARView()
                        } else {
                            print("Failed to create path from polyline string.")
                        }
                    }
                }
            } catch let error {
                print("Failed to parse directions: \(error)")
            }
        }.resume()
    }
}


extension UIImage {
    func fixedOrientation() -> UIImage {
        if imageOrientation == .up {
            return self
        }
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return normalizedImage ?? self
    }
}

extension simd_float4x4 {
    init(_ cmRotationMatrix: CMRotationMatrix) {
        self.init(columns: (
            SIMD4(Float(cmRotationMatrix.m11), Float(cmRotationMatrix.m12), Float(cmRotationMatrix.m13), 0),
            SIMD4(Float(cmRotationMatrix.m21), Float(cmRotationMatrix.m22), Float(cmRotationMatrix.m23), 0),
            SIMD4(Float(cmRotationMatrix.m31), Float(cmRotationMatrix.m32), Float(cmRotationMatrix.m33), 0),
            SIMD4(0, 0, 0, 1)
        ))
    }
}
