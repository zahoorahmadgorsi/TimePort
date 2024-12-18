//
//  Constant.swift
//  GoogleMapDemo
//
//  Created by ViPrak-Rohit on 14/09/24.
//

import Foundation
import UIKit
import CoreLocation

//var photo = capturedPhoto,
//var location = currentLocation,
//var heading = currentHeading,
//var tilt = currentTilt

//MARK: - Structures -
struct PhotoData: Codable {
    let photoData: Data?
    let locationData: LocationData?
    let headingValue: Double?
    let tilt: TiltData?  // Replacing the tuple with a struct

    var photo: UIImage? {
        if let data = photoData {
            return UIImage(data: data)
        }
        return nil
    }

    var location: CLLocation? {
        return locationData?.toCLLocation()
    }
}

struct TiltData: Codable {
    let pitch: Double
    let roll: Double
    let yaw: Double
}

struct LocationData: Codable {
    let latitude: Double
    let longitude: Double
    let altitude: Double
    let horizontalAccuracy: Double
    let verticalAccuracy: Double
    
    // Initialize from CLLocation
    init(location: CLLocation) {
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        self.altitude = location.altitude
        self.horizontalAccuracy = location.horizontalAccuracy
        self.verticalAccuracy = location.verticalAccuracy
    }
    
    // Convert back to CLLocation
    func toCLLocation() -> CLLocation {
        return CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            altitude: altitude,
            horizontalAccuracy: horizontalAccuracy,
            verticalAccuracy: verticalAccuracy,
            timestamp: Date()
        )
    }
}

struct placeDetailResponse: Codable {
    let htmlAttributions: [String]?
    let nextPageToken: String?
    let results: [Result]?
    let status: String?

    enum CodingKeys: String, CodingKey {
        case htmlAttributions = "html_attributions"
        case nextPageToken = "next_page_token"
        case results, status
    }
}

struct Result: Codable {
    let geometry: Geometry?
    let icon: String?
    let iconBackgroundColor: IconBackgroundColor?
    let iconMaskBaseURI: String?
    let name: String?
    let photos: [Photo]?
    let placeID, reference: String?
    let scope: Scope?
    let types: [String]?
    let vicinity: String?
    let businessStatus: BusinessStatus?
    let openingHours: OpeningHours?
    let plusCode: PlusCode?
    let rating: Double?
    let userRatingsTotal: Int?
    let permanentlyClosed: Bool?
    let priceLevel: Int?

    enum CodingKeys: String, CodingKey {
        case geometry, icon
        case iconBackgroundColor = "icon_background_color"
        case iconMaskBaseURI = "icon_mask_base_uri"
        case name, photos
        case placeID = "place_id"
        case reference, scope, types, vicinity
        case businessStatus = "business_status"
        case openingHours = "opening_hours"
        case plusCode = "plus_code"
        case rating
        case userRatingsTotal = "user_ratings_total"
        case permanentlyClosed = "permanently_closed"
        case priceLevel = "price_level"
    }
}

struct Geometry: Codable {
    let location: Location?
    let viewport: Viewport?
}

struct Location: Codable {
    let lat, lng: Double?
}

struct Viewport: Codable {
    let northeast, southwest: Location?
}

struct OpeningHours: Codable {
    let openNow: Bool?

    enum CodingKeys: String, CodingKey {
        case openNow = "open_now"
    }
}

struct Photo: Codable {
    let height: Int?
    let htmlAttributions: [String]?
    let photoReference: String?
    let width: Int?

    enum CodingKeys: String, CodingKey {
        case height
        case htmlAttributions = "html_attributions"
        case photoReference = "photo_reference"
        case width
    }
}

struct PlusCode: Codable {
    let compoundCode, globalCode: String?

    enum CodingKeys: String, CodingKey {
        case compoundCode = "compound_code"
        case globalCode = "global_code"
    }
}

//MARK: - Enums -
enum BusinessStatus: String, Codable {
    case closedTemporarily = "CLOSED_TEMPORARILY"
    case operational = "OPERATIONAL"
}

enum IconBackgroundColor: String, Codable {
    case ff9E67 = "#FF9E67"
    case the4B96F3 = "#4B96F3"
    case the7B9Eb0 = "#7B9EB0"
}

enum Scope: String, Codable {
    case google = "GOOGLE"
}
