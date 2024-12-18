//
//  PhotoListVC.swift
//  Timeport
//
//  Created by iMac on 08/11/24.
//

import UIKit
import CoreData

class PhotoListVC: UIViewController {

    //MARK: - @IBOutlet
    @IBOutlet weak var listTbl: UITableView!
    
    //MARK: - Variables
    var arrPhotosData: [PhotoEntity]?

    //MARK: - Override Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        self.registerTblCell()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.main.async {
            self.arrPhotosData = self.fetchSavedPhotoData()
            self.listTbl.reloadData()
        }
    }
}

//MARK: - UITableViewDataSource, UITableViewDelegate
extension PhotoListVC: UITableViewDataSource, UITableViewDelegate {
    func registerTblCell() {
        self.listTbl.dataSource = self
        self.listTbl.delegate   = self
        self.listTbl.register(UINib(nibName: "PhotoListTblCell", bundle: nil), forCellReuseIdentifier: "PhotoListTblCell")
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return  self.arrPhotosData?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PhotoListTblCell", for: indexPath) as! PhotoListTblCell
        
        let dic = self.arrPhotosData?[indexPath.row]
        
        cell.imgNameLbl.text = "\(indexPath.row+1). \(dic?.imageName ?? "No Name...!")"
        cell.imgDescLbl.text = "\(dic?.imageDesc ?? "No Description...!")"
        
        cell.photoImgView.image = UIImage(data: dic?.photoData ?? Data())
        
        return cell
    }
}

//MARK: - Helper Methods
extension PhotoListVC {
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
}
