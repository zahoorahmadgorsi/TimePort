//
//  ShowPhotoVC.swift
//  Timeport
//
//  Created by iMac on 08/11/24.
//

import UIKit

class ShowPhotoVC: UIViewController {

    //MARK: - @IBOutlet 
    @IBOutlet weak var closeBtn: UIButton!
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var imgNameLbl: UILabel!
    @IBOutlet weak var imgDescLbl: UILabel!
    
    var selectedImage = UIImage(named: "")
    var imageName = ""
    var discription = ""
    
        
    //MARK: - Override Methods 
    override func viewDidLoad() {
        super.viewDidLoad()
        imgView.image = selectedImage
        imgNameLbl.text = imageName
        imgDescLbl.text = discription
        imgView.isUserInteractionEnabled = true
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        imgView.addGestureRecognizer(pinchGesture)
    }
    
    @objc func handlePinch(_ sender: UIPinchGestureRecognizer) {
            guard let view = sender.view else { return }
            
            // Adjust the scale of the image
            view.transform = view.transform.scaledBy(x: sender.scale, y: sender.scale)
            
            // Reset the scale of the gesture recognizer to avoid compounding
            sender.scale = 1.0
        }
    
    //MARK: - @IBAction 
    @IBAction func onClickCloseBtn(_ sender: UIButton) {
        DispatchQueue.main.async {
            self.dismiss(animated: true)
        }
    }
}
