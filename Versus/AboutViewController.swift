//
//  AboutViewController.swift
//  Versus
//
//  Created by Dongkeun Lee on 9/29/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit
import ActiveLabel

class AboutViewController: UIViewController {

    
    @IBOutlet weak var termsAndPolicies: ActiveLabel!
    @IBOutlet weak var circleImageView: ActiveLabel!
    @IBOutlet weak var glide: ActiveLabel!
    @IBOutlet weak var gregorCresnar: ActiveLabel!
    @IBOutlet weak var freepik: ActiveLabel!
    @IBOutlet weak var chanut: ActiveLabel!
    @IBOutlet weak var eleanorWang: ActiveLabel!
    @IBOutlet weak var icomoon: ActiveLabel!
    @IBOutlet weak var pixelPerfect: ActiveLabel!
    @IBOutlet weak var antonSaputro: ActiveLabel!
    @IBOutlet weak var vectorsMarket: ActiveLabel!
    @IBOutlet weak var pavelKozlov: ActiveLabel!
    @IBOutlet weak var hanan: ActiveLabel!
    @IBOutlet weak var googleMaterialDesign: ActiveLabel!
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let termsAndPoliciesType = ActiveType.custom(pattern: "Terms and Policies")
        termsAndPolicies.enabledTypes.append(termsAndPoliciesType)
        termsAndPolicies.customize { label in
            termsAndPolicies.customColor[termsAndPoliciesType] = UIColor(red: 0.0, green: 122.0/255, blue: 1, alpha: 1)
            
            termsAndPolicies.handleCustomTap(for: termsAndPoliciesType) { _ in
                guard let url = URL(string: "https://www.versusdaily.com/terms-and-policies") else { return }
                UIApplication.shared.open(url)
            }
        }
        
        let circleImageViewType = ActiveType.custom(pattern: "CircleImageView")
        circleImageView.enabledTypes.append(circleImageViewType)
        circleImageView.customize { label in
            circleImageView.customColor[circleImageViewType] = UIColor(red: 0.0, green: 122.0/255, blue: 1, alpha: 1)
            
            circleImageView.handleCustomTap(for: circleImageViewType) { _ in
                guard let url = URL(string: "https://github.com/hdodenhof/CircleImageView/blob/master/LICENSE.txt") else { return }
                UIApplication.shared.open(url)
            }
        }
        
        let glideType = ActiveType.custom(pattern: "Glide")
        glide.enabledTypes.append(glideType)
        glide.customize { label in
            glide.customColor[glideType] = UIColor(red: 0.0, green: 122.0/255, blue: 1, alpha: 1)
            
            glide.handleCustomTap(for: glideType) { _ in
                guard let url = URL(string: "https://github.com/bumptech/glide/blob/master/LICENSE") else { return }
                UIApplication.shared.open(url)
            }
        }
        
        let gregorCresnarType = ActiveType.custom(pattern: "Gregor Cresnar")
        gregorCresnar.enabledTypes.append(gregorCresnarType)
        gregorCresnar.customize { label in
            gregorCresnar.customColor[gregorCresnarType] = UIColor(red: 0.0, green: 122.0/255, blue: 1, alpha: 1)
            
            gregorCresnar.handleCustomTap(for: gregorCresnarType) { _ in
                guard let url = URL(string: "https://www.flaticon.com/authors/gregor-cresnar") else { return }
                UIApplication.shared.open(url)
            }
        }
        
        let freepikType = ActiveType.custom(pattern: "Freepik")
        freepik.enabledTypes.append(freepikType)
        freepik.customize { label in
            freepik.customColor[freepikType] = UIColor(red: 0.0, green: 122.0/255, blue: 1, alpha: 1)
            
            freepik.handleCustomTap(for: freepikType) { _ in
                guard let url = URL(string: "https://www.flaticon.com/authors/freepik") else { return }
                UIApplication.shared.open(url)
            }
        }
        
        let chanutType = ActiveType.custom(pattern: "Chanut")
        chanut.enabledTypes.append(chanutType)
        chanut.customize { label in
            chanut.customColor[chanutType] = UIColor(red: 0.0, green: 122.0/255, blue: 1, alpha: 1)
            
            chanut.handleCustomTap(for: chanutType) { _ in
                guard let url = URL(string: "https://www.flaticon.com/authors/chanut") else { return }
                UIApplication.shared.open(url)
            }
        }
        
        let eleanorWangType = ActiveType.custom(pattern: "Eleanor Wang")
        eleanorWang.enabledTypes.append(eleanorWangType)
        eleanorWang.customize { label in
            eleanorWang.customColor[eleanorWangType] = UIColor(red: 0.0, green: 122.0/255, blue: 1, alpha: 1)
            
            eleanorWang.handleCustomTap(for: eleanorWangType) { _ in
                guard let url = URL(string: "https://www.flaticon.com/authors/eleonor-wang") else { return }
                UIApplication.shared.open(url)
            }
        }
        
        let icomoonType = ActiveType.custom(pattern: "Icomoon")
        icomoon.enabledTypes.append(icomoonType)
        icomoon.customize { label in
            icomoon.customColor[icomoonType] = UIColor(red: 0.0, green: 122.0/255, blue: 1, alpha: 1)
            
            icomoon.handleCustomTap(for: icomoonType) { _ in
                guard let url = URL(string: "https://www.flaticon.com/authors/icomoon") else { return }
                UIApplication.shared.open(url)
            }
        }
        
        let pixelPerfectType = ActiveType.custom(pattern: "Pixel Perfect")
        pixelPerfect.enabledTypes.append(pixelPerfectType)
        pixelPerfect.customize { label in
            pixelPerfect.customColor[pixelPerfectType] = UIColor(red: 0.0, green: 122.0/255, blue: 1, alpha: 1)
            
            pixelPerfect.handleCustomTap(for: pixelPerfectType) { _ in
                guard let url = URL(string: "https://www.flaticon.com/authors/pixel-perfect") else { return }
                UIApplication.shared.open(url)
            }
        }
        
        let antonSaputroType = ActiveType.custom(pattern: "Anton Saputro")
        antonSaputro.enabledTypes.append(antonSaputroType)
        antonSaputro.customize { label in
            antonSaputro.customColor[antonSaputroType] = UIColor(red: 0.0, green: 122.0/255, blue: 1, alpha: 1)
            
            antonSaputro.handleCustomTap(for: antonSaputroType) { _ in
                guard let url = URL(string: "https://www.flaticon.com/authors/anton-saputro") else { return }
                UIApplication.shared.open(url)
            }
        }
        
        let vectorsMarketType = ActiveType.custom(pattern: "Vectors Market")
        vectorsMarket.enabledTypes.append(vectorsMarketType)
        vectorsMarket.customize { label in
            vectorsMarket.customColor[vectorsMarketType] = UIColor(red: 0.0, green: 122.0/255, blue: 1, alpha: 1)
            
            vectorsMarket.handleCustomTap(for: vectorsMarketType) { _ in
                guard let url = URL(string: "https://www.flaticon.com/authors/vectors-market") else { return }
                UIApplication.shared.open(url)
            }
        }
        
        let pavelKozlovType = ActiveType.custom(pattern: "Pavel Kozlov")
        pavelKozlov.enabledTypes.append(pavelKozlovType)
        pavelKozlov.customize { label in
            pavelKozlov.customColor[pavelKozlovType] = UIColor(red: 0.0, green: 122.0/255, blue: 1, alpha: 1)
            
            pavelKozlov.handleCustomTap(for: pavelKozlovType) { _ in
                guard let url = URL(string: "https://www.flaticon.com/authors/pavel-kozlov") else { return }
                UIApplication.shared.open(url)
            }
        }
        
        let hananType = ActiveType.custom(pattern: "Hanan")
        hanan.enabledTypes.append(hananType)
        hanan.customize { label in
            hanan.customColor[hananType] = UIColor(red: 0.0, green: 122.0/255, blue: 1, alpha: 1)
            
            hanan.handleCustomTap(for: hananType) { _ in
                guard let url = URL(string: "https://www.flaticon.com/authors/hanan") else { return }
                UIApplication.shared.open(url)
            }
        }
        
        let googleMaterialDesignType = ActiveType.custom(pattern: "Google Material Design")
        googleMaterialDesign.enabledTypes.append(googleMaterialDesignType)
        googleMaterialDesign.customize { label in
            googleMaterialDesign.customColor[googleMaterialDesignType] = UIColor(red: 0.0, green: 122.0/255, blue: 1, alpha: 1)
            
            googleMaterialDesign.handleCustomTap(for: googleMaterialDesignType) { _ in
                guard let url = URL(string: "https://github.com/google/material-design-icons") else { return }
                UIApplication.shared.open(url)
            }
        }
        
        
        
        
        
    }
    
    
    
    @IBAction func closeAbout(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
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
