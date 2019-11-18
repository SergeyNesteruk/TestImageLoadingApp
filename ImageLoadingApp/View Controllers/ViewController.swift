//
//  ViewController.swift
//  ImageLoadingApp
//
//  Created by Sergii Nesteruk on 10/10/19.
//  Copyright © 2019 NLab. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var imageModels = [ImageModel]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageModels = ImageModel.loadData()
    }
    
    // MARK: - UITableViewDataSource, UITableViewDelegate methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return imageModels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ImageTableViewCell.reuseIdentifier, for: indexPath)
        if let cell = cell as? ImageTableViewCell {
            cell.configure(for: imageModels[indexPath.row])
        }
        return cell
    }
}

