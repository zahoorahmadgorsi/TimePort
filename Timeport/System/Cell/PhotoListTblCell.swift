//
//  PhotoListTblCell.swift
//  Timeport
//
//  Created by iMac on 08/11/24.
//

import UIKit

class PhotoListTblCell: UITableViewCell {
    
    //MARK: - @IBOutlet 
    @IBOutlet weak var photoImgView: UIImageView!
    @IBOutlet weak var imgNameLbl: UILabel!
    @IBOutlet weak var imgDescLbl: UILabel!
    
    //MARK: - Override Methods 
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
}
