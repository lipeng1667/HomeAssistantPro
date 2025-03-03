//
//  IntroViewController.swift
//  HomeAssistantPro
//
//  Created by KaKa on 2/20/25.
//

import UIKit

class IntroViewController: UIPageViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLable: UILabel!

    var pageIndex: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        switch pageIndex {
        case 0:
            imageView.image = UIImage(named: "")
        default:
            break
        }
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
